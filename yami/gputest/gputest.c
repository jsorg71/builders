
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <locale.h>
#include <pthread.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <yami_inf.h>

static int g_num_sessions = 0;
static char g_in_filename[256];
static char g_out_filename[256];
static int g_got_out_filename = 0;
static char* g_data = 0;
static int g_in_file_bytes = 0;
static int g_width = 1024;
static int g_height = 768;

struct nv_info
{
    void* handle;
    int frames;
    pthread_mutex_t mutex;
    int in_bytes;
    int out_bytes;
    int comp_ratio;
};

static struct nv_info g_sessions[1024];

int process_args(int argc, char** argv)
{
    int index;

    if (argc < 2)
    {
        printf("args\n");
        printf("%s -s <num sessions> "
                       "-i <input yuv file in nv12 format> "
                       "-o <output h264 file> "
                       "-w <width in pixels> "
                       "-h <height in pixels>\n", argv[0]);
        return 1;
    }
    for (index = 1; index < argc; index++)
    {
        if (strcmp(argv[index], "-s") == 0)
        {
            g_num_sessions = atoi(argv[++index]);
        }
        if (strcmp(argv[index], "-i") == 0)
        {
            strcpy(g_in_filename, argv[++index]);
        }
        if (strcmp(argv[index], "-o") == 0)
        {
            strcpy(g_out_filename, argv[++index]);
            g_got_out_filename = 1;
            unlink(g_out_filename);
        }
        if (strcmp(argv[index], "-w") == 0)
        {
            g_width = atoi(argv[++index]);
        }
        if (strcmp(argv[index], "-h") == 0)
        {
            g_height = atoi(argv[++index]);
        }
    }
    return 0;
}

static int g_frame = 1;

/*****************************************************************************/
static int
n_save_data(const char* filename, const void* data, int data_size)
{
    int fd;
    struct _header
    {
        char name[4];
        int width;
        int height;
        int bytes_after;
    } header;

    header.name[0] = 'B';
    header.name[1] = 'E';
    header.name[2] = 'E';
    header.name[3] = 'F';
    header.width = g_width;
    header.height = g_height;
    header.bytes_after = data_size;
    fd = open(filename, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
    if (fd == -1)
    {
        return 1;
    }
    printf("frame %d     %d\n", g_frame++, data_size);
    lseek(fd, 0, SEEK_END);
    if (write(fd, &header, sizeof(header)) != sizeof(header))
    {
        printf("save_data: write failed\n");
    }
    if (write(fd, data, data_size) != data_size)
    {
        printf("save_data: write failed\n");
    }
    close(fd);
    return 0;
}

void * start_routine(void* arg)
{
    int actualDataSize;
    int rv;
    int index;
    int data_offset;
    char* ls8;
    char* ld8;
    void* ydata;
    int ydata_stride_bytes;
    void* uvdata;
    int uvdata_stride_bytes;
    void* cdata = malloc(1024 * 1024);
    int cdata_max_bytes;
    struct nv_info* nvi = (struct nv_info*) arg;

    printf("thread started\n");
    data_offset = 0;
    nvi->frames = 0;
    for (;;)
    {
        rv = yami_encoder_get_ybuffer(nvi->handle, &ydata, &ydata_stride_bytes);
        if (rv != YI_SUCCESS)
        {
            break;
        }
        ls8 = g_data + data_offset;
        ld8 = (char*)ydata;
        for (index = 0; index < g_height; index++)
        {
            memcpy(ld8, ls8, g_width);
            ls8 += g_width;
            ld8 += ydata_stride_bytes;
        }
        rv = yami_encoder_get_uvbuffer(nvi->handle, &uvdata, &uvdata_stride_bytes);
        if (rv != YI_SUCCESS)
        {
            break;
        }
        ls8 = g_data + data_offset + g_width * g_height;
        ld8 = (char*)uvdata;
        for (index = 0; index < g_height; index += 2)
        {
            memcpy(ld8, ls8, g_width);
            ls8 += g_width;
            ld8 += uvdata_stride_bytes;
        }
        cdata_max_bytes = 1024 * 1024;
        rv = yami_encoder_encode(nvi->handle, cdata, &cdata_max_bytes);
        if (rv != YI_SUCCESS)
        {
            break;
        }
        actualDataSize = cdata_max_bytes;
        if (g_got_out_filename)
        {
            n_save_data(g_out_filename, cdata, cdata_max_bytes);
        }

        data_offset += g_width * g_height * 3 / 2;
        pthread_mutex_lock(&(nvi->mutex));
        nvi->frames++;
        nvi->in_bytes += g_width * g_height * 3 / 2;
        nvi->out_bytes += actualDataSize;
        if (data_offset >= g_in_file_bytes)
        {
            data_offset = 0;
            nvi->comp_ratio = nvi->in_bytes / (nvi->out_bytes + 1);
            nvi->in_bytes = 0;
            nvi->out_bytes = 0;
            g_got_out_filename = 0;
        }
        pthread_mutex_unlock(&(nvi->mutex));
    }
    printf("thread exit\n");
    return 0;
}

int main(int argc, char** argv)
{
    int index;
    int fd;
    int drm_fd;
    int rv;
    pthread_t thread;

    struct stat st;

    setlocale(LC_CTYPE, "");
    setbuf(stdout, NULL);

    if (process_args(argc, argv) != 0)
    {
        return 0;
    }

    drm_fd = open("/dev/dri/renderD128", O_RDWR);
    rv = yami_init(YI_TYPE_DRM, (void*)(size_t)drm_fd);
    if (rv != YI_SUCCESS)
    {
        printf("yami_init failed\n");
        return 1;
    }

    if (g_got_out_filename && g_num_sessions > 1)
    {
        printf("turning off -o because more tha one session requested\n");
        g_got_out_filename = 0;
    }

    memset(g_sessions, 0, sizeof(g_sessions));

    if (stat(g_in_filename, &st) == 0)
    {
        g_data = (char*) malloc(st.st_size + 16);
        if (g_data == 0)
        {
            printf("malloc failed\n");
            return 1;
        }
    }
    else
    {
        printf("problem getting in file size\n");
        return 1;
    }

    fd = open(g_in_filename, O_RDONLY);
    if (fd == -1)
    {
        printf("failed to open %s\n", g_in_filename);
        return 1;
    }
    g_in_file_bytes = read(fd, g_data, st.st_size);
    if (g_in_file_bytes < 16)
    {
        printf("read failed\n");
        return 1;
    }

    printf("read file size %d\n", g_in_file_bytes);

    printf("about to init %d sessions width %d height %d\n", g_num_sessions, g_width, g_height);
    for (index = 0; index < g_num_sessions; index++)
    {
        printf("calling yami_encoder_create\n");
        rv = yami_encoder_create(&(g_sessions[index].handle),
                                 g_width, g_height, YI_TYPE_H264,
                                 YI_H264_ENC_FLAGS_PROFILE_MAIN);
        if (rv != YI_SUCCESS)
        {
            printf("session %d failed\n", index);
            return 1;
        }
        else
        {
            printf("session %d ok\n", index);
        }
    }
    for (index = 0; index < g_num_sessions; index++)
    {
        pthread_mutex_init(&(g_sessions[index].mutex), 0);
        memset(&thread, 0, sizeof(thread));
        rv = pthread_create(&thread, 0, start_routine, g_sessions + index);
        if (rv == 0)
        {
            rv = pthread_detach(thread);
            if (rv != 0)
            {
                printf("pthread_detach failed rv %d\n", rv);
                return 1;
            }
        }
        else
        {
            printf("pthread_create failed rv %d\n", rv);
            return 1;
        }
    }
    for (;;)
    {
        int cr;
        for (index = 0; index < g_num_sessions; index++)
        {
            pthread_mutex_lock(&(g_sessions[index].mutex));
            cr = g_sessions[index].comp_ratio;
            printf("thread %d frames %d(fps) compression ratio %d\n", index, g_sessions[index].frames, cr);
            g_sessions[index].frames = 0;
            pthread_mutex_unlock(&(g_sessions[index].mutex));
        }
        usleep(1000 * 1000);
    }
    getchar();
    return 0;
}
