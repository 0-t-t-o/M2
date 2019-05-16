#ifndef _free_algebra_quotient_hpp_
#define _free_algebra_quotient_hpp_

#include "FreeAlgebra.hpp"
#include "SuffixTree.hpp"
#include <memory>

class FreeAlgebraQuotient : public our_new_delete
{
private:
  const FreeAlgebra& mFreeAlgebra;
  std::unique_ptr<ConstPolyList> mGroebner;
  WordTable mWordTable;
  //SuffixTree mWordTable;
  int mMaxdeg;
  
public:
  FreeAlgebraQuotient(const FreeAlgebra& A, std::unique_ptr<ConstPolyList> GB, int maxdeg);

  const FreeMonoid& monoid() const { return mFreeAlgebra.monoid(); }
  const Monoid& degreeMonoid() const { return monoid().degreeMonoid(); }
  const FreeAlgebra& freeAlgebra() const { return mFreeAlgebra; } 
  
  const Ring* coefficientRing() const { return mFreeAlgebra.coefficientRing(); }

  int numVars() const { return monoid().numVars(); }
  
  unsigned int computeHashValue(const Poly& a) const; // TODO

  void normalizeInPlace(Poly& f) const;
  
  void init(Poly& f) const {}
  void clear(Poly& f) const;
  void setZero(Poly& f) const;

  void from_coefficient(Poly& result, const ring_elem a) const;
  void from_long(Poly& result, long n) const;
  void from_int(Poly& result, mpz_srcptr n) const; 
  bool from_rational(Poly& result, const mpq_ptr q) const; 
  void copy(Poly& result, const Poly& f) const;
  void swap(Poly& f, Poly& g) const; // TODO
  void var(Poly& result, int v) const;
  void from_word(Poly& result, const std::vector<int>& word) const; 
  void from_word(Poly& result, ring_elem coeff, const std::vector<int>& word) const; 
  
  long n_terms(const Poly& f) const { return f.numTerms(); }  
  bool is_unit(const Poly& f) const;
  bool is_zero(const Poly& f) const { return n_terms(f) == 0; }
  bool is_equal(const Poly& f, const Poly& g) const;
  int compare_elems(const Poly& f, const Poly& g) const;
  
  void negate(Poly& result, const Poly& f) const; 
  void add(Poly& result, const Poly& f, const Poly& g) const;
  void subtract(Poly& result, const Poly& f, const Poly& g) const;
  void mult(Poly& result, const Poly& f, const Poly& g) const;
  void power(Poly& result, const Poly& f, int n) const;
  void power(Poly& result, const Poly& f, mpz_ptr n) const;

  ring_elem eval(const RingMap *map, const Poly& f, int first_var) const;
  
  void elem_text_out(buffer &o,
                     const Poly& f,
                     bool p_one,
                     bool p_plus,
                     bool p_parens) const;

  bool is_homogeneous(const Poly& f) const;
  void degree(const Poly& f, int *d) const;
  // returns true if f is homogeneous, and sets already_allocated_degree_vector
  // to be the LCM of the exponent vectors of the degrees of all terms in f.
  bool multi_degree(const Poly& f, int *already_allocated_degree_vector) const;

  SumCollector* make_SumCollector() const;
};

// for debugging purposes
class FreeAlgebraQuotientElement
{
public:
  FreeAlgebraQuotientElement(const FreeAlgebraQuotient* F)
    : mRing(F)
  {
    mRing->init(mPoly);
  }
  ~FreeAlgebraQuotientElement()
  {
    mRing->clear(mPoly);
  }
  Poly& operator*()
  {
    return mPoly;
  }
  const Poly& operator*() const
  {
    return mPoly;
  }
  bool operator==(const FreeAlgebraQuotientElement& g) const
  {
    return this->mRing->is_equal(**this,*g);
  }
  FreeAlgebraQuotientElement operator+(const FreeAlgebraQuotientElement& g)
  {
    FreeAlgebraQuotientElement result(mRing);
    mRing->add(*result, **this, *g);
    return result;  // this is a copy
  }
  FreeAlgebraQuotientElement operator-(const FreeAlgebraQuotientElement& g)
  {
    FreeAlgebraQuotientElement result(mRing);
    mRing->subtract(*result, **this, *g);
    return result;  // this is a copy
  }
  FreeAlgebraQuotientElement operator*(const FreeAlgebraQuotientElement& g)
  {
    FreeAlgebraQuotientElement result(mRing);
    mRing->mult(*result, **this, *g);
    return result;  // this is a copy
  }
  FreeAlgebraQuotientElement operator^(int n)
  {
    FreeAlgebraQuotientElement result(mRing);
    mRing->power(*result, **this, n);
    return result;  // this is a copy
  }
  
private:
  const FreeAlgebraQuotient* mRing;
  Poly mPoly;
};

#endif

// Local Variables:
// compile-command: "make -C $M2BUILDDIR/Macaulay2/e "
// indent-tabs-mode: nil
// End:

