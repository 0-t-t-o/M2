todo list being redone with start of semester, 22 Aug 2019 FM+MS
0. rename PolynomialAlgebra.m2 package.  To AssociativeAlgebras.  DONE
1. get code back working:  rawNCFreeAlgebra has changed arguments.
  Fix the code that calls this. DONE
2. Get other monomial orders working: mainly elimination orders, also different degrees. DONE
3. Make a series of tests for noncomm gc.
4. Clean this file up: get rid of old cruft code.
5. Play with magma, singular, bergman, gap for noncomm performance.
6. Run profiler on our nc gb code.  What do we need to improve?
7. document this package
The following more specific list is still active todo as well:

todo: for "today":
  1. debug NCGB
  1a. put tests, clean up code, code review.
  2. add in computation type, some functions to query
      computation object
      make one
      compute it (soft degree bound)
      get answer from it
      get status
      add interrupts to M2
      add gbTrace usage.
  3. NCAlgebra class (quotient of a free algebra) (DONE)
  4. SuffixTree (this code is functional, but perhaps is buggy, or performance buggy).
  5. Better reduction (heap, poly with pos, using hashtables)
  6. F4 like reduction of overlap pairs.
also:
  change local rings to not use braces for construction.  
  
Also important todo: update NCAlgebra package to use this engine code.


-- TODO:
-- Engine code:
-- 1. eval for FreeAlgebraQuotient, separate heap from FreeAlgebra for use in FreeAlgebraQuotient
-- 2. PolyWithPos for reduction code/use heaps there as well
-- 3. Inhomogeneous GBs (rabbit)
-- 4. ncBasis in multidegree
-- 5. heft vectors for multidegrees
-- 6. bug with ncBasis(-1,ring)
-- 7. How to tell the difference between finding the entire GB and hitting a degree cap
-- 8. Add weight vectors for more general monomial orders (elimination, etc)
-- Top Level Code:
-- 1. Documentation
-- 2. Tests
-- 3. Convert left/rightMult to new basis code
-- 4. Convert central/normal elements to new basis code

-- play with listForm
-- calls rawPairs, which calls IM2_RingElement_list_form in engine
-- each ring has its own "list_form(coeff ring, ring_elem)"

-- TODO: 1/3/19 MS+FM (DONE means: make sure there are tests for it!!)
-- 1. isEqual DONE
-- 2. mutable matrices DONE
-- 3. promote/lift DONE
-- 4. rawPairs, etc (rawPairs: DONE)
-- 5. leadTerm/Coefficient/Monomial (NOT DONE)
-- 6. terms DONE
-- 7. degrees/weights of variables (NOT DONE)
-- 8. listForm (Not correct for NC case): use rawSparseListFormMonomial.
-- 9. check on ring map evaluation.
-- eventually: 
--  a. want ring of square matrices over a ring.
--  b. Endomorphism ring and/or Ext algebra.
--  c. Skew poly rings
--  d. path algebra?
-- not written:
--   is_homogeneous
--   degree
--   multi_degree
-- order of events:
--  a. fix the little stuff above.
--   a1. then get existing bergman interface to work with this code.
--  b. understand bergman GB/res algorithms/tricks.
--  c. implement GB and res
--  d. add in these other non-commutative rings.
-- Eventually: make a front end type: NCMonoid, or FreeMonoid, ...
--   have AssociativeAlgebras::create use that, instead of create one.
-- Get torsion in a monoid to work.

-------------------------------

Steps to make NCalgebra arithmetic in the engine

restart
debug Core    
kk = QQ
R = rawNCFreeAlgebra(raw kk, ("a","b","c"), raw degreesRing 1)
1_R
a = R_0
b = R_1
c = R_2
-a
a*b*a*b*b*a*a*a
a > b
a < b
a >= b
a <= b
a == b -- not sure why this is returning true
a*b*a*b*b*a*a*c > a*b*a*b*b*a*a*b
a*b*b*a*a*c > a*b*a*b*b*a*a*b
a*b*a*b*b*a*a*c > a*b*b*a*a*b
f = a+b+c
-- this thing takes up a lot of memory... 3^12 terms!
time(f*f*f*f*f*f*f*f*f*f*f*f);
time(f3 = f*f*f);
time(f3*f3*f3*f3);
g = a-b-c
f*g-g*f
f*f


restart
needsPackage "NCAlgebra"
R = QQ{a,b,c}
f = a+b+c
elapsedTime time(f^12);
M = ncMatrix {{a,b},{c,a}}
elapsedTime(M^10);

restart
debug Core    
kk = QQ
R = rawNCFreeAlgebra(raw kk, ("a","b","c"), raw degreesRing 1)
1_R
a = R_0
b = R_1
c = R_2

matrix{{f}}
R^5
a * rawIdentity(R^5, 5)
rawMutableMatrix(R,4,4,true)
elems = toSequence flatten {{a,b,c},{b*a,c*a,a*c}}
M = rawMatrix1(R^2, 3, elems, 0)
N = rawDual M
M*N
oo * oo

elems = toSequence flatten {{a,b},{c,a}}
M = rawMatrix1(R^2, 2, elems, 0)
M*M*M
time (M*M*M*M*M*M*M*M*M*M);

M = rawMutableMatrix(R,4,4,false) -- crashes


R = QQ {a,b,c}
coefficientRing R
f = a*a*a*a*a + a*b*a*b;
terms f
ring f
rawPairs(raw coefficientRing R, raw f)

time g = f^20;
time g = f^10;
time h = g*g;
f + f^2
R_0

restart
needsPackage "NCAlgebra"
R = QQ {a,b,c}
f = a*a*a*a*a + a*b*a*b;
time g = f^20;

restart
needsPackage "PolynomialAlgebra"
R = QQ {a,b,c}
f = a*a*a*a*a + a*b*a*b;
time g = f^20;

R_0
gens R

kk = QQ
R = rawNCFreeAlgebra(raw kk, ("a","b","c"), raw degreesRing 1)
A = newNCEngineRing R;


