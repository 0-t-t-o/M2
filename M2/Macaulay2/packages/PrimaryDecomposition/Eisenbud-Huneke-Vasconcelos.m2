-- This code is based on/taken from the paper
-- "Direct methods for primary decomposition" by 
-- Eisenbud, Huneke, and Vasconcelos that appeared in
-- Inventiones Math. 110, 207-235 (1992)

--
--
-- This first section of the file defines the assassinator.
-- There are two strategies defined first
--
--

ass1 := (I) -> (
     if I.cache#?"AssociatedPrimes" then I.cache#"AssociatedPrimes" else I.cache#"AssociatedPrimes" = (
     assassinator := {};
     RI := ring I;
     polyRing := ring presentation RI;
     I1 := lift(I, polyRing);
     i := codim I1;
     d := dim polyRing;
     local currentext;
     C := resolution(cokernel generators I, LengthLimit => d+1);
     --here we look at the associated primes of the i-th
     --ext and pick out the height i components ala EisenbudHunekeVasconcelos
     while i <= d do ( 
	  if debugLevel >= 2 then (<< "  associatedPrimes loop " << i << endl);
	  currentext = Ext^i(polyRing^1/I1,polyRing);
	  if codim currentext == i then (
	       firstlist := minimalPrimes ann currentext;
	       scan(firstlist, P -> (if codim P == i then (
			      if debugLevel >= 1 then << "    " << P  << endl << endl ;
			      assassinator = append(assassinator,P)))
		    ) );
	  i=i+1;);
     assassinator = apply( assassinator, P -> (trim substitute(P, RI)) );
     assassinator
     ))


-- WARNING: this code below does NOT compute the associated primes of I.
-- Why not? (MES, 3 Jul 2006).
ass2 := (I) -> (
     if I.cache#?"AssociatedPrimes" then I.cache#"AssociatedPrimes" else I.cache#"AssociatedPrimes" = (
     assassinator := {};
     local newcomponents;
     RI := ring I;
     polyRing := ring presentation RI;
     currentI := lift(I,polyRing);
     topcurrentI := topComponents currentI;
     while not isSubset(topcurrentI, currentI) do(
	if debugLevel >= 2 then print "  beginning new associatedPrimes loop";
        newcomponents = flatten minimalPrimes topcurrentI;
	if debugLevel >=1 then (scan(newcomponents, P -> ( << endl << "    " << P << endl)));
	assassinator = append(assassinator, newcomponents);
	  currentI = currentI:topcurrentI;
	  topcurrentI = topComponents currentI;
	  );
     newcomponents = flatten minimalPrimes topcurrentI;
     if debugLevel >=1 then (scan(newcomponents, P -> ( << endl << "    " << P << endl)));
     assassinator = append(assassinator, newcomponents);
     assassinator = flatten assassinator;
     assassinator = apply(
	  assassinator, P -> (trim substitute(P,RI))
	  );
     assassinator 
     ))


associatedPrimes Ideal := List => o -> (I) -> ass1 I

TEST ///
-- This last little code is to check if two lists are the
-- same up to permutation.

isSameList = (L1,L2) ->(
     ret := null;
     ret1 := true;
     counter1 := 0;
     counter2 := 0;
     if #L1 =!= #L2 then ret = false else(
     	  while counter1 < #L1 and ret1 == true do (
	     ret2 := false;
	     counter2 = 0;
	     while counter2 < #L2 and ret2 == false do(
		    if L1#counter1 == L2#counter2 
		    then ret2 = true;
		    counter2 = counter2 + 1;
		    );
	       if ret2 == false then ret1 = false;
	       counter1 = counter1 + 1;);
	  ret = ret1;
	  );
     ret	       
     )     	    

R=ZZ/(101)[x,y,z];
I=ideal (x^2,x*y);
assoutcome = associatedPrimes(I,Strategy=>1)
trueass = {ideal(x),ideal(x,y)};
assert(isSameList(assoutcome,trueass))

I=ideal (x^2,x*y);
assoutcome = associatedPrimes(I,Strategy=>2)
isSameList(assoutcome, trueass)
S=R/I;
J=ideal(0_S);	
assoutcome = associatedPrimes J
trueass = {ideal(x),ideal(x,y)};
assert(isSameList(assoutcome, trueass))

R=ZZ/31991[x,y,z]
I1 = ideal(x^3,x*y,z^2);
I2 = ideal(x,y+z);
I3 = ideal(x^5*z,y^3*z^2);
K=intersect(I1,I2,I3)
assoutcome = associatedPrimes K
trueass = {ideal(z), ideal(y,x), ideal(z,x), ideal(y+z,x)}     
assert(isSameList(assoutcome, trueass))
///


--In localize, P is an associated prime.
--This routine computes the localization of I at P.
--For this version, we have to know associatedPrimes I

SYlocalize := (assroutine) -> (I,P) ->(
     local ret;
     RI := ring I;
     polyRing := ring presentation RI;
     I1 := lift(I,polyRing);
     P1 := lift(P,polyRing);
     IntersectionOfPrimes := ideal (1_polyRing);
     if debugLevel >= 1 then (<< endl << "Finding the assassinator of " << I1 << endl);
     Assasin := assroutine I1;
     if debugLevel >= 2 then (<< endl << "It equals " << Assasin << endl);
     RP := polyRing/P1;
     scan(Assasin, Q -> if not isSubset(Q,P) 
	  then (IntersectionOfPrimes = 
	       intersect(IntersectionOfPrimes,Q))
	  );
     IOPrp := substitute(IntersectionOfPrimes,RP);
     if IntersectionOfPrimes == ideal(1_RI) 
     then ret = I
     else (
	  if debugLevel >= 1 then (<< endl << "Finding a separator polynomial" << endl);
	  f := lift((flatten entries generators gb IOPrp)#0, polyRing);
	  if debugLevel >= 2 then (<< endl << "It equals " << f << endl);
	  f = substitute (f,RI);
	  if debugLevel >= 1 then (<< endl << "Saturating with respect to the separator polynomial" << endl);
	  ret = saturate(I,f);
	  );
     ret
     ) 

-- alternate localize: you only need to know I and the prime
-- this only works if it's homogeneous and equidimensional
-- and radical. 

EHVlocalize := (I,P) ->(
     polyRing := ring presentation ring I;
     I0 := lift(I,polyRing);
     P0 := lift(P,polyRing);
     d := degree I0;
     if debugLevel >= 1 then (<< endl << "Finding the " << d*(d+1) << " power of the prime ideal" << endl);
     P0Power := P0^(d*(d+1));
     if debugLevel >= 2 then << endl << "It equals " << P0Power << endl;
     if debugLevel >= 1 then (<< endl << "Finding the top of " << I0 + P0Power << endl);
     I1 := topComponents (I0 + P0Power);
     if debugLevel >= 2 then(<< endl << "It equals " << endl << I1 << endl);
     gensI1 := flatten entries mingens I1;
     gensI1 = apply(gensI1, g -> 
	  if first degree g <= d then g else 0);
     I2 := ideal gensI1;
     if debugLevel >= 1 then (<< endl << "Finding the final top" << endl);
     I3 := topComponents I2;
     if debugLevel >= 2 then (<< endl << "It equals " << endl << I3 << endl);
     if debugLevel >= 1 then (<< endl << "Finding the radical" << endl);
     --radical I3;
     trim substitute(I3,ring I)
     )

localize = method(Options =>{ Strategy => 1})

localize (Ideal,Ideal) := Ideal => o -> (I,P) -> (
     if o.Strategy === 0 then (
	  if debugLevel >=1 then print "localize:  Using Strategy 0";
	  EHVlocalize(I,P))
     else if o.Strategy === 1 then (
	  if debugLevel >=1 then print "localize:  Using Strategy 1";
	  (SYlocalize ass1)(I,P))
     else (
	  if debugLevel >=1 then print "localize:  Using Strategy 2";
	  (SYlocalize ass2)(I,P))
     )

TEST ///
R = ZZ/(101)[x,y];
I = ideal (x^2,x*y);
P1 = ideal (x);
outcome = localize(I,P1)
outcome == P1
P2 = ideal (x,y);
outcome = localize(I,P2)
outcome == I

R = ZZ/(31991)[x,y,z];
I = ideal(x^2,x*z,y*z);
P1 = ideal(x,y);
outcome = localize(I,P1)
outcome == P1
P2 = ideal(x,z);
outcome = localize(I,P2)
trueanswer = ideal(x^2,z);
outcome == trueanswer
///

--This part should compute the/a primary component of I
--corresponding to P.
--A BIG issue here is how to increment m.  this could make
--a big speed difference.

-- Of course in this next thing, if we know associatedPrimes, we can use
-- localize, but if we just know I and the prime, we might 
-- rather use EHVlocalize.  It's hard to know.  
primarycomponent := (localizeroutine) -> 
     (I,P,inc) -> (
	  polyRing := ring presentation ring I;
	  I0 := lift(I,polyRing);
	  P0 := lift(P,polyRing);
	  ret := null;
	  m := 1;
	  I0P0 := localizeroutine (I0,P0);
	  ImportantColonIdeal := saturate (I0P0,P0);
	  while ret === null do (
	       if debugLevel >= 1 then (<< endl << "primaryComponent checking power " << m << endl);
	       if debugLevel >= 2 then (<< endl << "Computing topComponents of " << I0 << "+ the power of " << P0 << 
		    endl);
	       Q := topComponents (I0 + P0^m);
	       if debugLevel >= 2 then (<< endl << "It equals " << Q << endl); 
	       IIntersection := intersect(Q,ImportantColonIdeal);
	       if isSubset(IIntersection,I0P0) 
	       then ret = Q 
	       else m = m+inc;
	       );
	  trim substitute(ideal mingens ret,ring I)
	  )

primaryComponent = method( Options => { Strategy => 2, Increment =>1 })

primaryComponent(Ideal,Ideal) := Ideal => o -> (I,P) -> (
     localizefcn := if o.Strategy === 1 then
	  SYlocalize ass1
     else if o.Strategy === 2 then
	  SYlocalize ass2
     else EHVlocalize;
     (primarycomponent localizefcn)(I,P,o.Increment))

TEST ///
R = ZZ/(101)[x,y];
I = ideal (x^2,x*y);
P1 = ideal (x);
primaryComponent(I,P1)
P2 = ideal (x,y);
primaryComponent(I,P2)

R = ZZ/(31991)[x,y,z];
I = ideal(x^2,x*z,y*z);
P1 = ideal(x,y);
primaryComponent(I,P1)
P2 = ideal(x,z);
primaryComponent(I,P2)
///

--This computes a primary decomposition of an ideal.
EHVprimaryDecomposition = (I) -> (
    Assasin := associatedPrimes I;
    nprimes := #Assasin;
    counter := 0;
    ListofPrimaries := {};
    while counter < nprimes do (
	 newcomponent := primaryComponent(I, Assasin#counter);
	 ListofPrimaries = append(ListofPrimaries, newcomponent);
    	 counter = counter + 1;
	 );
     ListofPrimaries
     )

--This computes a primary decomposition of an ideal.
HprimaryDecomposition = (I,assstrategy,localizestrategy) -> (
     assroutine := (
	  if assstrategy === 1 then ass1
	  else ass2);
     localizeroutine := (
	  if localizestrategy === 1 then EHVlocalize
	  else SYlocalize assroutine);
     primarycomponentroutine := primarycomponent(localizeroutine);
     Assasin := assroutine I;
     nprimes := #Assasin;
     counter := 0;
     ListofPrimaries := {};
     while counter < nprimes do (
	  newcomponent := primarycomponentroutine(I, Assasin#counter, 1);
	  ListofPrimaries = append(ListofPrimaries, newcomponent);
    	  counter = counter + 1;
	  );
     ListofPrimaries
     )


TEST ///
R=ZZ/(101)[x,y,z];
I=ideal (x^2,x*y);
associatedPrimes(I,Strategy=>1)
associatedPrimes(I,Strategy=>2)
S=R/I;
J=ideal(0_S);
primaryDecomposition(J,Strategy=>EisenbudHunekeVasconcelos)
associatedPrimes J
P=ideal(x);

R = ZZ/31991[x,y,z]
J=ideal (x*y^2,x*z^2);
P2=ideal(y,z);
associatedPrimes(J)
localize (J,P2)
primaryComponent(J,P2)
primaryDecomposition(J,Strategy=>EisenbudHunekeVasconcelos)

R = ZZ/101[a..d]
S = R/(a*b-c^2)
T = S/(a^3,b^3)
J = ideal(c)
ring presentation T
J1 = lift(J,ring presentation T)
J1 = J1 + ideal(R_3^5)
trim substitute(J1,T)
///


-- Primary decomposition code for modules (Macaulay2)
-- Author: Justin Chen (justin.chen@math.gatech.edu)
-- Last edited: 7/3/2020

associatedPrimes Module := List => opts -> M -> ( -- modified code in ass1 for modules
     if M.cache#?"AssociatedPrimes" and not M.cache#?"associatedPrimesCodimLimit" then M.cache#"AssociatedPrimes" else M.cache#"AssociatedPrimes" = (
     ringRel := presentation ring M;
     polyRing := ring ringRel;
     M1 := lift(M, polyRing);
     -- M1 := subquotient(lift(gens M, polyRing), lift(relations M, polyRing) | ringRel);
     c := codim M1;
     d := dim polyRing;
     n := if opts.CodimensionLimit >= 0 then min(d, opts.CodimensionLimit) else d;
     if c == d and isHomogeneous M then return {sub(ideal gens polyRing, ring M)};
     C := resolution(M1, LengthLimit => 1+n);
     if n < d then M.cache#"associatedPrimesCodimLimit" = n
     else remove(M.cache, "associatedPrimesCodimLimit");
     (flatten apply(toList(c..n), i -> (
          if debugLevel > 0 then print("Computing associated primes of codim " | toString i);
          A := image transpose C.dd_i : ker transpose C.dd_(i+1); -- ann Ext^i(M, R) (consider colon.m2)
          select(minimalPrimes A, P -> codim P == i)
     )))/(P -> trim sub(P, ring M))
     )
)
associatedPrimes Ring := List => opts -> R -> associatedPrimes comodule ideal R

bracketPower = (I, n) -> ideal apply(I_*, f -> f^n)

primaryDecomposition Module := List => o -> M -> ( -- returns a primary decomposition of 0 in M
     if not M.cache#?"primaryComponents" then M.cache#"primaryComponents" = new MutableHashTable;
     AP := associatedPrimes M;
     if #AP == 1 then M.cache#"primaryComponents"#(AP#0) = 0*M;
     if #values(M.cache#"primaryComponents") != #AP then (
          H := hashTable apply(AP, p -> p => select(#AP, i -> isSubset(AP#i, p)));
          for i to #AP - 1 do ( -- assumes all embedded primes appear after all primes they contain, i.e. isSubset(AP#i, AP#j) => i \le j
               if debugLevel > 0 then print("Prime: " | toString(i+1) | "/" | toString(#AP));
               p := AP#i;
               if M.cache#"primaryComponents"#?p then continue;
               f := product(AP - set AP_(H#p), q -> q_(position(q_*, g -> g % p != 0)));
               isolComp := if f == 1 then 0*M else saturate(0*M, f);
               if #(H#p) > 1 then (
                    colonMod := intersect apply(delete(i, H#p), k -> M.cache#"primaryComponents"#(AP#k));
                    (j, Q) := (4, topComponents(M, bracketPower(p,2)*M, codim p));
                    while not (image relations M == image relations Q and isSubset(intersect(colonMod, Q), isolComp)) 
                    do (j, Q) = (2*j, trim topComponents(M, bracketPower(p,j)*M, codim p));
               ) else Q = isolComp;
               M.cache#"primaryComponents"#p = Q;
          );
     );
     apply(AP, p -> M.cache#"primaryComponents"#p)
)
primaryDecomposition Ring := List => opts -> R -> primaryDecomposition comodule ideal R

TEST /// -- non-cyclic modules
R = QQ[x_0..x_3]
I = monomialCurveIdeal(R,{1,2,3})
J = monomialCurveIdeal(R,{1,3,4})
K = monomialCurveIdeal(R,{1,4,5})
M = comodule I ++ comodule J ++ comodule K -- direct sum
AP = associatedPrimes M
assert(set associatedPrimes M === set{I,J,K})
comps = primaryDecomposition M
assert(intersect comps == 0 and all(comps, isPrimary_M))
N = coker map(M, R^1, transpose matrix{{1_R,1,1}}) -- coker of diagonal map
assert(numcols mingens N == 2 and #associatedPrimes N == 5)
comps = primaryDecomposition N
assert(intersect comps == 0 and all(comps, isPrimary_N))
///

TEST /// -- multiply embedded prime
-- Use new topComponents(Module, Module, ZZ)
R = QQ[x_0..x_3]
I = intersect((ideal(x_0..x_3))^5, (ideal(x_0..x_2))^4, (ideal(x_0..x_1))^3)
M = comodule I
AP = associatedPrimes M
comps = primaryDecomposition M
assert(intersect comps == 0 and all(comps, isPrimary_M))
///

TEST /// -- tough example for old primaryDecomposition, good on new code for modules
-- Example 4.4 in https://arxiv.org/pdf/2006.13881.pdf
R = QQ[x_0..x_5]
P = minors(2, matrix{{x_0,x_1,x_3,x_4},{x_1,x_2,x_4,x_5}}) -- surface scroll S(2,2) in P^5
L = P^2_*; I = ideal (L_0 + L_9, L_0 + L_12, L_13 + L_20)
M = comodule I
assert(#associatedPrimes M == 5)
comps = primaryDecomposition M
assert(sum(comps, Q -> degree(I + ideal gens Q)) == degree I)
///

-- Local Variables:
-- compile-command: "make -C $M2BUILDDIR/Macaulay2/packages PrimaryDecomposition.installed "
-- End:
