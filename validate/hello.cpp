#include <iostream>
#include <numeric>
#include <stdexcept>
#include <thread>
#include <vector>

thread_local int tls_value = 7;

struct Guard {
    int &count;
    ~Guard() { ++count; }
};

struct Base {
    virtual ~Base() = default;
};

struct Derived : Base {};

int main()
{
    std::vector<int> values{1, 2, 3, 4};
    int result = 0;

    std::thread worker([&] {
        tls_value = 11;
        result = std::accumulate(values.begin(), values.end(), 0)
               + tls_value;
    });
    worker.join();

    if (result != 21 || tls_value != 7)
        return 1;

    int destroyed = 0;
    bool caught = false;

    try {
        Guard guard{destroyed};
        throw std::runtime_error("exception test");
    } catch (const std::runtime_error &) {
        caught = true;
    }

    if (!caught || destroyed != 1)
        return 2;

    Derived object;
    Base *base = &object;
    if (dynamic_cast<Derived *>(base) != &object)
        return 3;

    std::cout << "C++ runtime validation passed\n";
    return 0;
}