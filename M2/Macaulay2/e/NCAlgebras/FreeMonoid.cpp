#include "FreeMonoid.hpp"

FreeMonoid::FreeMonoid(
          const std::vector<std::string>& variableNames,
          const PolynomialRing* degreeRing,
          const std::vector<int>& degrees,
          const std::vector<int>& wtvecs)
  : mVariableNames(variableNames),
    mDegreeRing(degreeRing),
    mDegrees(degrees),
    mWeightVectors(wtvecs),
    mNumWeights(wtvecs.size() / variableNames.size())
{
  auto ndegrees = degreeMonoid().n_vars();
  assert(nvars * ndegrees == mDegrees.size());

  for (const int* i = mDegrees.data(); i != mDegrees.data() + mDegrees.size(); i += ndegrees)
    {
      int* deg = degreeMonoid().make_one();
      degreeMonoid().from_expvector(i, deg);
      mDegreeOfVar.push_back(deg);
    }
}

void FreeMonoid::one(MonomialInserter& m) const
{
  m.push_back(mNumWeights+1);
  for (int i=0; i<mNumWeights; ++i) m.push_back(0);
}

void FreeMonoid::var(int v, MonomialInserter& m) const
{
  m.push_back(mNumWeights+2);
  for (int i=0; i<mNumWeights; ++i)
    m.push_back(weightOfVar(v,i));
  m.push_back(v);
}

bool FreeMonoid::is_one(const Monom& m) const
{
  return m[0] == mNumWeights+1;
}

int FreeMonoid::index_of_variable(const Monom& m) const
{
  if (m[0] != mNumWeights+2) return -1;
  return m[mNumWeights+1];
}

void FreeMonoid::copy(const Monom& m, MonomialInserter& result) const
{
  for (auto v : m) result.push_back(v);
  
  //  for (auto i = m.begin(); i != m.end(); ++i)
  //    result.push_back(*i);
  //  std::copy(m.begin(), m.end(), result);
}

void FreeMonoid::mult(const Monom& m1, const Monom& m2, MonomialInserter& result) const
{
  result.push_back(m1[0] + wordLength(m2));
  for (int i=1; i<=mNumWeights; ++i)
    result.push_back(m1[i] + m2[i]);
  // FM : Should we be using vector::insert?
  for (auto i = m1.begin()+mNumWeights+1; i != m1.end(); ++i)
    result.push_back(*i);
  for (auto i = m2.begin()+mNumWeights+1; i != m2.end(); ++i)
    result.push_back(*i);
}

void FreeMonoid::mult3(const Monom& m1, const Monom& m2, const Monom& m3, MonomialInserter& result) const
{
  result.push_back(m1[0] + wordLength(m2) + wordLength(m3));
  for (int i=1; i<=mNumWeights; ++i)
    result.push_back(m1[i] + m2[i] + m3[i]);
  for (auto i = m1.begin()+mNumWeights+1; i != m1.end(); ++i)
    result.push_back(*i);
  for (auto i = m2.begin()+mNumWeights+1; i != m2.end(); ++i)
    result.push_back(*i);
  for (auto i = m3.begin()+mNumWeights+1; i != m3.end(); ++i)
    result.push_back(*i);
}

int FreeMonoid::compare(const Monom& m1, const Monom& m2) const
{
  // order of events:
  // compare weights first
  // then compare word length
  // then compare with lex

  for (int j = 1; j <= mNumWeights; ++j)
    {
      if (m1[j] > m2[j]) return GT;
      if (m1[j] < m2[j]) return LT;
    }
  int m1WordLen = wordLength(m1);
  int m2WordLen = wordLength(m2);  
  if (m1WordLen > m2WordLen) return GT;
  if (m1WordLen < m2WordLen) return LT;
  // at this stage, they have the same weights and word length, so use lex order
  for (int j = mNumWeights+1; j < m1WordLen + mNumWeights + 1; ++j)
    {
      if (m1[j] > m2[j]) return LT;
      if (m1[j] < m2[j]) return GT;
    }
  // if we are here, the monomials are the same.
  return EQ;
}

void FreeMonoid::multi_degree(const Monom& m, int* already_allocated_degree_vector) const
{
  int* result = already_allocated_degree_vector; // just to use a smaller name...
  degreeMonoid().one(result); // reset value

  auto word_length = wordLength(m);
  auto word_ptr = m + mNumWeights+1;
  for (auto j = 0; j < word_length; j++)
    {
      degreeMonoid().mult(result, mDegreeOfVar[word_ptr[j]], result);
    }
}
    
void FreeMonoid::elem_text_out(buffer& o, const Monom& m) const
{
  auto word_length = wordLength(m);
  auto word_ptr = m + mNumWeights + 1;
  for (auto j = 0; j < word_length; j++)
    {
      // for now, just output the string.
      int curvar = word_ptr[j];
      int curvarPower = 0;
      o << mVariableNames[curvar];
      while ((j < word_length) && (word_ptr[j] == curvar))
        {
          j++;
          curvarPower++;
        }
      if (curvarPower > 1) o << "^" << curvarPower;
      // back j up one since we went too far looking ahead.
      j--;
    }
}

// This function should reverse the order of the varpower terms.
// as the front end reverses the order of terms in a monomial.
void FreeMonoid::getMonomial(Monom m, std::vector<int>& result) const
// Input is of the form: [len wt1 .. wtm v1 v2 ... vn]
//                        where len = m + n + 1, wt are the weights, and vs are the variables in the word
// The output is of the following form, and appended to result.
// [2n+1 v1 e1 v2 e2 ... vn en], where each ei > 0, (in 'varpower' format)
// and the order is that of m.  that is: a*b is encoded as [5, 0 1, 1 1] (commas are only for clarity)
{
  auto start = result.size();
  result.push_back(0);

  auto word_length = wordLength(m);
  auto word_ptr = m + mNumWeights + 1;
  for (auto j = 0; j < word_length; j++)
    {
      int curvar = word_ptr[j];
      int curvarPower = 0;
      result.push_back(curvar);
      while ((j < word_length) && (word_ptr[j] == curvar))
        {
          j++;
          curvarPower++;
        }
      result.push_back(curvarPower);
      // back j up one since we went too far looking ahead.
      --j;
    }
  result[start] = static_cast<int>(result.size() - start);
}

void FreeMonoid::getMonomialReversed(Monom m, std::vector<int>& result) const
// Input is of the form: [len wt1 .. wtm v1 v2 ... vn]
//                        where len = m + n + 1, wt are the weights, and vs are the variables in the word
// The output is of the following form, and appended to result.
// [2n+1 v1 e1 v2 e2 ... vn en], where each ei > 0, (in 'varpower' format)
// and the order is the OPPOSITE of m.  that is: a*b is encoded as [5, 1 1, 0 1] (commas are only for clarity)
{
  auto start = result.size();
  result.push_back(0);
  auto word_length = wordLength(m);
  auto word_ptr = m + mNumWeights + 1;
  for (auto j = word_length-1; j >= 0; --j)
    {
      int curvar = word_ptr[j];
      int curvarPower = 0;
      result.push_back(curvar);
      while ((j >= 0) && (word_ptr[j] == curvar))
        {
          --j;
          curvarPower++;
        }
      result.push_back(curvarPower);
      // back j up one since we went too far looking ahead.
      j++;
    }
  result[start] = static_cast<int>(result.size() - start);
}

// This function should reverse the order of the varpower terms
void FreeMonoid::fromMonomial(const int* monom, MonomialInserter& result) const
  // Input is of the form: [2n+1 v1 e1 v2 e2 ... vn en] (in 'varpower' format)
  // The output is of the following form, and stored in result.
  // [len wt1 wt2 ... wtm v1 v2 v3 ... vn]
  // where len = m+n+1 and wt1 .. wtm are the weights and v1 .. vn is the word 
{
  int inputMonomLength = *monom;
  int startMon = static_cast<int>(result.size());  
  // make space for the length and the weights
  for (int i=0; i<mNumWeights+1; ++i)
    result.push_back(0);
  for (int j = inputMonomLength-2; j >= 1; j -= 2)
    {
      auto v = monom[j];
      for (int k = 0; k < monom[j+1]; k++)
        {
          result.push_back(v);
        }
    }
  result[startMon] = static_cast<int>(result.size() - startMon);
  Monom tmpMon(result.data()+startMon);
  setWeights(tmpMon);
}

// these functions create a Word from the (prefix/suffix of) a Monom
void FreeMonoid::wordFromMonom(Word& result, const Monom& m) const
{
  // just call the prefix command on the word length of the monom
  wordPrefixFromMonom(result,m,wordLength(m));
}

void FreeMonoid::wordPrefixFromMonom(Word& result, const Monom& m, int endIndex) const 
{
  result.init(m.begin() + mNumWeights + 1, m.begin() + mNumWeights + 1 + endIndex);
}

void FreeMonoid::wordSuffixFromMonom(Word& result, const Monom& m, int beginIndex) const
{
  result.init(m.begin() + mNumWeights + 1 + beginIndex, m.end());
}

void FreeMonoid::monomInsertFromWord(MonomialInserter& result, const Word& word) const
{
  result.push_back(word.size() + mNumWeights + 1);
  for (int j = 0; j < mNumWeights; ++j)
    result.push_back(0);
  for (auto a : word) result.push_back(a);
  Monom tmpMon(result.data());
  setWeights(tmpMon);
}

void FreeMonoid::setWeights(Monom& m) const
{
  // since Monoms are wrappers to const ints, it seems we need
  // this line so we can set the weights, but I'm not 100% sure
  auto monom = const_cast<int*>(m.begin());

  int word_len = wordLength(m);
  for (int j = 0; j < mNumWeights; ++j)
      monom[j + 1] = 0;
  for (int j = 0; j < word_len; ++j)
    {
      for (int k = 0; k < mNumWeights; ++k)
        {
          monom[k] += weightOfVar(m[j],k);
        }
    }
}

// Local Variables:
// compile-command: "make -C $M2BUILDDIR/Macaulay2/e "
// indent-tabs-mode: nil
// End:
