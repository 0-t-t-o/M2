-------------------------------
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
  3. NCAlgebra class (quotient of a free algebra)
  4. SuffixTree
  5. Better reduction (heap, poly with pos, using hashtables)
  6. F4 like reduction of overlap pairs.
-------------------------------


-- Monomial type: want to allow non-commutative values in front end.
--   any obstructions to do this?
  RawMonomial -- at m2 level
  RawMonomialCell
  RawMonomialArray
  RawMonomialOrNull
  RawArrayPair
  RawMonomailPair
  RawMonomailPairOrNull
  *, ^, /, ==
  tostring, hash
  rawVarMonomial
  rawSparseListFormMonomial
  rawMakeMonomial
  rawMonomialIsOne
  rawCompareMonomial
  rawMonomialDivides
  rawMonomialDivide
  rawGCD
  rawLCM
  rawSaturateMonomial
  rawSyzygy
  rawColonMonomial
  rawLeadMonomial
  toExpr

  used in 'listForm RingElement'
  used in 'standardForm RingElement'
  used in 'leadMonomial RingElement'  (rawLeadMonomial)
  leadTerm -> someTerms --> rawGetTerms(nvars, rawelem, lo, hi) (doesn't use Monomial)
  
  Question: how to create a Monomial at top level?
  
  monomial.{hpp,cpp}: make_noncommutative
---------------------------------------

Steps to make NCalgebra arithmetic in the engine

. make a rawNCFreeAlgebra(coeff ring, NCmonoid?):
    NCAlgebra.m2 will call this function when making a ring
    in d/interface.dd: write a "hook" for the e dir routine
    in e/engine.h: write a declaration for this function
    in e/NCAlgebra.{hpp,cpp}, we include
      a type NCFreeAlgebra
      the class NCFreeAlgebra does the arithmetic.
        R->add(f,g) --> h ("raw pointers")

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

-- Creating a new NCAlgebra Ring
restart
debug Core    
NCPolynomialRing = new Type of EngineRing
NCPolynomialRing.synonym = "noncommutative polynomial ring"
new NCPolynomialRing from List := (EngineRing, inits) -> new EngineRing of RingElement from new HashTable from inits
Ring List := (R, varList) -> (
   -- get the symbols associated to the list that is passed in, in case the variables have been used earlier.
   if #varList == 0 then error "Expected at least one variable.";
   if #varList == 1 and class varList#0 === Sequence then varList = toList first varList;
   varList = varList / baseName;
   rawA := rawNCFreeAlgebra(raw R, toSequence(varList/toString), raw degreesRing 1);
   A := new NCPolynomialRing from {
       (symbol rawRing) => rawA,
       (symbol generators) => {},
       (symbol generatorSymbols) => varList,
       (symbol degreesRing) => degreesRing 1,
       (symbol CoefficientRing) => R,
       (symbol cache) => new CacheTable from {},
       (symbol baseRings) => {ZZ,R}
       };
   newGens := for i from 0 to #varList-1 list varList#i <- new A from A.rawRing_i;
   A#(symbol generators) = newGens;
   --- need to fix net of an RingElement coming from a NCPolynomial ring.
   net A := f -> net raw f;
   A);
NCPolynomialRing _ ZZ := (A, n) -> (A.generators)#n
coefficientRing NCPolynomialRing := A -> last A.baseRings

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

R_0
gens R

kk = QQ
R = rawNCFreeAlgebra(raw kk, ("a","b","c"), raw degreesRing 1)
A = newNCEngineRing R;

>>>>>>> Stashed changes
