#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int initialized;

__attribute__((constructor))
static void initialize(void)
{
    initialized = 42;
}

int main(void)
{
    char *message = malloc(64);
    if (!message)
        return 1;

    strcpy(message, "Hello from musl!");

    if (initialized != 42 || strlen(message) != 16) {
        free(message);
        return 2;
    }

    puts(message);
    free(message);
    return 0;
}