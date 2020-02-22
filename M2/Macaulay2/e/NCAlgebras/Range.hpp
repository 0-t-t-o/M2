#ifndef __range__
#define __range__

#include <utility>
#include <vector>

template<typename T>
class Range
{
private:
  T* mFirst;
  T* mLast;
public:
  Range(T* first, T* last) : mFirst(first), mLast(last) {}
  Range(std::pair<T*, T*> a) : mFirst(a.first), mLast(a.second) {}
  
  explicit Range(const std::vector<T>& vec) : mFirst(vec.data()), mLast(vec.data() + vec.size()) {}

  int size() const { return mLast - mFirst; }
  T* begin() { return mFirst; }
  T* end() { return mLast; }

  const T* cbegin() const { return mFirst; }
  const T* cend() const { return mLast; }
};

#endif

// Local Variables:
// compile-command: "make -C $M2BUILDDIR/Macaulay2/e  "
// indent-tabs-mode: nil
// End:
