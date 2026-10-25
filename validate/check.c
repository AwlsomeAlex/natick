#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <linux/limits.h>

_Static_assert(sizeof(void *) == 8, "Expected a 64-bit target");

unsigned __int128 divide(unsigned __int128 a, unsigned __int128 b)
{
    return a / b;
}