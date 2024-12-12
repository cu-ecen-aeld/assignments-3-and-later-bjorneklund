# Define compiler and flags
CC := $(CROSS_COMPILE)gcc
CFLAGS := -Wall -Werror -g

# Define the source and target
TARGET := writer
SRCS := writer.c
OBJS := $(SRCS:.c=.o)

# Default target
.PHONY: all
all: $(TARGET)

# Rule to build the target application
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

# Rule to build object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean target
.PHONY: clean
clean:
	rm -f $(TARGET) $(OBJS)
