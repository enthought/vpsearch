#ifndef FASTQUEUE_H
#define FASTQUEUE_H

#include <algorithm>
#include <limits>
#include <vector>

const float INF = std::numeric_limits<float>::infinity();


class Neighbor : public std::pair<float, size_t>
{
public:
    Neighbor(float distance, size_t index)
        : std::pair<float, size_t>(distance, index) {}
    
    bool operator<(const Neighbor& other) const 
    {
        return first < other.first;
    }
};


class FastNeighborQueue
{
public:
    // Dummy nullary constructor just to keep Cython happy...
    FastNeighborQueue() {}
    FastNeighborQueue(size_t size) : size(size) {}

    void push(const Neighbor& element) 
    {
        if (elements.size() < size) {
            elements.push_back(element);
            max_el = elements.begin();
        } else {
            if (element < *max_el) {
                *max_el = element;
                max_el = std::max_element(elements.begin(), elements.end());
            }
        }
    }
    
    void push_distance(float distance, size_t index)
    {
        push(Neighbor(distance, index));
    }

    float get_max_distance() const
    {
        if (elements.empty()) {
            return INF;
        } else {
            return max_el->first;
        }
    }
    
    typedef typename std::vector<Neighbor>::iterator iterator;
    // typedef typename std::vector<Neighbor>::const_iterator const_iterator;
    
    iterator begin() noexcept
    {
        return elements.begin();
    }
    iterator end() noexcept
    {
        return elements.end();
    }

    
private:
    size_t size;
    std::vector<Neighbor> elements;
    iterator max_el;
};
    

#endif // FASTQUEUE_H
