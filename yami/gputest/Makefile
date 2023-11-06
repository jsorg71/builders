
OBJS = gputest.o

CFLAGS = -O2 -Wall -I/opt/yami/include/libyami -I/opt/yami/include

LDFLAGS = -L/opt/yami/lib -Wl,-rpath,/opt/yami/lib

LIBS = -lyami_inf -pthread

all: gputest

gputest: $(OBJS)
	$(CC) -o gputest $(OBJS) $(LDFLAGS) $(LIBS)

clean:
	rm -f gputest $(OBJS)

