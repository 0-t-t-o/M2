---------------------------------------------------------------------------
-- PURPOSE : Computation of saturations and quotient ideals
--
-- PROGRAMMERS :
--
-- UPDATE HISTORY : created 14 April 2018 at M2@UW;
--                  updated July 2020
--
-- TODO : 1. move annihilator functions here as well?
---------------------------------------------------------------------------
newPackage(
    "Colon",
    Version => "0.2",
    Date => "July 25, 2020",
    Headline => "saturation and ideal and submodule colon/quotient routines",
    Authors => {
	{Name => "Justin Chen",    Email => "justin.chen@math.gatech.edu"},
	{Name => "Mahrud Sayrafi", Email => "mahrud@umn.edu",        HomePage => "https://math.umn.edu/~mahrud"},
	{Name => "Mike Stillman",  Email => "mike@math.cornell.edu", HomePage => "http://www.math.cornell.edu/~mike"}},
    PackageExports => { "Elimination" },
    AuxiliaryFiles => true,
    DebuggingMode => true
    )

export {
    "saturationZero",
    "intersectionByElimination"
    }

-- TODO: where should these be placed?

-- TODO: is this the right function?
ambient Ideal := Ideal => I -> ideal 1_(ring I)

--Ideal % Matrix            :=
--remainder(Ideal,  Matrix) := Matrix => (I, m) -> remainder(gens I, m)
--Module % Matrix           :=
--remainder(Module, Matrix) := Matrix => (M, m) -> remainder(gens M, m)

--------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------

debugInfo = (func, A, B, strategy) -> if debugLevel > 0 then (
    stderr << concatenate("  -- ", toString func, "(", toString class A, ", ", toString class B, ", Strategy => ", toString strategy, ")") << endl);

removeOptions := (opts, badopts) -> (
    opts = new MutableHashTable from opts;
    scan(badopts, k -> remove(opts, k));
    new OptionTable from opts)

removeQuotientOptions := opts -> (
    opts = new MutableHashTable from opts;
    remove(opts, Strategy);
    remove(opts, MinimalGenerators);
    -- TODO: what would this do?
    --opts.SyzygyLimit = opts.BasisElementLimit;
    --remove(opts,BasisElementLimit);
    new OptionTable from opts)

isFlatPolynomialRing = (R) -> (
     -- R should be a ring
     -- determines if R is a poly ring over ZZ or a field
     kk := coefficientRing R;
     isPolynomialRing R and (kk === ZZ or isField kk))

isGRevLexRing = (R) -> (
     -- returns true if the monomial order in the polynomial ring R
     -- is graded reverse lexicographic order, w.r.t. the first degree
     -- vector in the ring.
     mo := (options monoid R).MonomialOrder;
     mo = select(mo, x -> x#0 =!= MonomialSize and x#0 =!= Position);
     isgrevlex := mo#0#0 === GRevLex and mo#0#1 === apply(degrees R, first);
     #mo === 1 and isgrevlex and all(mo, x -> x#0 =!= Weights and x#0 =!= Lex))

-- Helper for Linear strategies
isLinearForm := f -> (
    degreeLength ring f > 0 and
    first degree f === 1 and
    all(first \ degrees ring f, x -> x === 1))

-- Return (R1, R1<-R, R<-R1), where generators i and n are switched
grevLexRing = method()
grevLexRing(ZZ, Ring) := (i, R) -> (
    X := local X;
    n := numgens R;
    degs := degrees R;
    if i === n - 1 then return (R, identity, identity);
    perm := toList splice(0..i-1, n-1, i+1..n-2, i);
    R1 := (coefficientRing R)[X_1..X_n, Degrees => degs_perm, MonomialSize => 16];
    fto := map(R1, R, (generators R1)_perm);
    fback := map(R, R1, (generators R)_perm);
    (R1, fto, fback))

eliminationInfo = method()
eliminationInfo Ring := (cacheValue symbol eliminationInfo)(R -> (
	X := local X;
	n := numgens R;
	R1 := (coefficientRing R)[X_0..X_n, MonomialOrder => Eliminate 1, MonomialSize => 16];
	fto := map(R1, R, drop(generators R1, 1));
	fback := map(R, R1, matrix{{0_R}} | vars R);
	(R1, fto, fback)))

-- Fast intersection code
-- TODO: move elsewhere?
intersectionByElimination = method()
intersectionByElimination List          := (L)    -> fold(intersectionByElimination, L)
intersectionByElimination(Ideal, Ideal) := (I, J) -> (
    R := ring I;
    (R1, fto, fback) := eliminationInfo R;
    I1 := R1_0 * fto I;
    J1 := (1 - R1_0) * fto J;
    L := I1 + J1;
    --g := gens gb J;
    --g := groebnerBasis(J, Strategy => "MGB");
    g := groebnerBasis(L, Strategy => "F4"); -- TODO: try "MGB"
    p1 := selectInSubring(1, g);
    ideal fback p1)

-- TODO: where can this be used?
quotelem0 = (I, f) -> (
    -- I is an ideal, f is an element
    syz gb(matrix{{f}} | generators I,
	Strategy   => LongPolynomial,
	Syzygies   => true,
	SyzygyRows => 1))

--------------------------------------------------------------------
-- Quotients
--------------------------------------------------------------------
-- quotient methods:
-- 1. syzygies
-- 2. use elimination methods? I forget how?
-- 3. case: x is a variable, I is homogeneous
--    case: x is a polynomial
--    case: x is an ideal

--quotient = method(...) -- defined in m2/quotient.m2
quotient(Ideal,  Ideal)       := Ideal  => opts -> (I, J) -> quotientHelper(I, J, IdealIdealQuotientAlgorithms, opts)
quotient(Ideal,  RingElement) := Ideal  => opts -> (I, f) -> quotient(I, ideal f, opts)
Ideal  : RingElement          := Ideal  =>         (I, f) -> quotient(I, f)
Ideal  : Ideal                := Ideal  =>         (I, J) -> quotient(I, J)

quotient(Module, Ideal)       := Module => opts -> (M, I) -> quotientHelper(M, I, ModuleIdealQuotientAlgorithms, opts)
quotient(Module, RingElement) := Module => opts -> (M, f) -> quotient(M, ideal f, opts)
Module : RingElement          := Module =>         (M, f) -> quotient(M, f)
Module : Ideal                := Module =>         (M, I) -> quotient(M, I)

quotient(Module, Module)      := Ideal  => opts -> (M, N) -> quotientHelper(M, N, ModuleModuleQuotientAlgorithms, opts)
Module : Module               := Ideal  =>         (M, N) -> quotient(M, N)

-- Helper for quotient methods
quotientHelper = (A, B, algorithms, opts) -> (
    if (R := ring A) =!= ring B then error "expected objects in the same ring";
    -- note: if B \sub A then A:B should be "everything", but this can get slow
    B' := if instance(B, RingElement) then matrix{{B}} else gens B;
    if B == 0 or (target B' == target gens A and B' % gens A == 0)
    then return if class A === class B then ideal 1_R else ambient A; -- TODO: is there an easier way to do this?
--    if ambient A == target B' and gens ambient A % B' == 0 then return A; -- TODO: what should this be for Module : Module?

    strategy := opts.Strategy;
    doTrim := if opts.MinimalGenerators then trim else identity;
    -- See TODO in removeQuotientOptions
    --opts = removeOptions(opts, {Strategy, MinimalGenerators});
    opts = removeQuotientOptions opts;

    C := if strategy === null then runHooks(algorithms#null, (opts, A, B))
    else if algorithms#?strategy then (
	debugInfo(quotient, A, B, strategy);
	(algorithms#strategy opts)(A, B))
    else error("unrecognized Strategy for quotient: '", toString strategy, "'; expected: ", toString keys algorithms);

    if C =!= null then doTrim C else if strategy === null
    then error("no applicable method for quotient(", class A, ", ", class B, ")")
    else error("assumptions for quotient strategy ", toString strategy, " are not met"))

-- Algorithms for Ideal : Ideal
IdealIdealQuotientAlgorithms = new HashTable from {
    null    => symbol IdealIdealQuotientHooks,
    Iterate => opts -> (I, J) -> (
	R := ring I;
	M1 := ideal 1_R;
	scan(numgens J, i -> (
		f := J_i;
		if generators(f * M1) % (generators I) != 0 then (
		    M2 := quotient(I, f, opts, Strategy => Quotient);
		    M1 = intersect(M1, M2);
		    )));
	M1),

    Quotient => opts -> (I, J) -> (
	R := (ring I)/I;
	mR := transpose generators J ** R;
	g := syz gb(mR, opts,
            Strategy   => LongPolynomial,
            Syzygies   => true,
	    SyzygyRows => 1);
	-- The degrees of g are not correct, so we fix that here:
	-- g = map(R^1, null, g);
	lift(ideal g, ring I)),

    -- TODO
    Linear => opts -> (I, J) -> (
	-- assumptions: J is a single linear element, and everything is homogeneous
	if not isHomogeneous I
	or not isHomogeneous J or not isLinearForm J_0
	then return null;
	stderr << "warning: quotient strategy Linear is not yet implemented" << endl; null),
    }

-- Installing hooks for Ideal : Ideal
scan({Quotient, Iterate-*, Linear*-}, strategy -> addHook(IdealIdealQuotientAlgorithms#null,
	(opts, I, J) -> (debugInfo(quotient, I, J, strategy); IdealIdealQuotientAlgorithms#strategy opts)(I, J)))

-- Algorithms for Module : Ideal
ModuleIdealQuotientAlgorithms = new HashTable from {
    null    => symbol ModuleIdealQuotientHooks,
    Iterate => opts -> (M, J) -> (
	-- This is the iterative version, where I is a
	-- submodule of F/K, or ideal, and J is an ideal.
	M1 := super M;
	m := generators M | relations M;
	scan(numgens J, i -> (
		f := J_i;
		if generators(f*M1) % m != 0 then (
		    M2 := quotient(M, f, opts, Strategy => Quotient);
		    M1 = intersect(M1, M2);
		    )));
	M1),

    Quotient => opts -> (M, J) -> (
	m := generators M;
	F := target m;
	mm := generators M;
	if M.?relations then mm = mm | M.relations;
	j := transpose generators J;
	g := (j ** F) | (target j ** mm);
	-- We would like to be able to inform the engine that
	-- it is not necessary to compute various of the pairs
	-- of the columns of the matrix g.
	h := syz gb(g, opts,
	    Strategy   => LongPolynomial,
	    Syzygies   => true,
	    SyzygyRows => numgens F);
	if M.?relations then subquotient(h % M.relations, M.relations) else image h
	),

    Linear => opts -> (M, J) -> (
	-- assumptions: J is a single linear element, and everything is homogeneous
	if not isHomogeneous M
	or not isHomogeneous J or not isLinearForm J_0
	then return null;
	stderr << "warning: quotient strategy Linear is not yet implemented" << endl; null),
    }

-- Installing hooks for Module : Ideal
scan({Quotient, Iterate, Linear}, strategy -> addHook(ModuleIdealQuotientAlgorithms#null,
	(opts, I, J) -> (debugInfo(quotient, I, J, strategy); ModuleIdealQuotientAlgorithms#strategy opts)(I, J)))

-- Algorithms for Module : Module
ModuleModuleQuotientAlgorithms = new HashTable from {
    null    => symbol ModuleModuleQuotientHooks,
    Iterate => opts -> (I, J) -> (
	R := ring I;
	M1 := ideal 1_R;
	m := generators I | relations I;
	scan(numgens J, i -> (
		f := image (J_{i});
		-- it used to say f ** M1, but that can't have been right.
		-- I'm just guessing that M1 * f is better.  (drg)
		if generators(M1 * f) % m != 0
		then (
		    M2 := quotient(I, f, opts, Strategy => Quotient);
		    M1 = intersect(M1, M2);
		    )));
	M1),

    Quotient => opts -> (M,J) -> (
	m := generators M;
	if M.?relations then m = m | M.relations;
	j := adjoint(generators J, (ring J)^1, source generators J);
	F := target m;
	g := j | (dual source generators J ** m);
	-- << g << endl;
	-- We would like to be able to inform the engine that
	-- it is not necessary to compute various of the pairs
	-- of the columns of the matrix g.
	h := syz gb(g, opts,
	    Strategy   => LongPolynomial,
	    Syzygies   => true,
	    SyzygyRows => 1);
	ideal h),
    }

-- Installing hooks for Module : Module
scan({Quotient, Iterate}, strategy -> addHook(ModuleModuleQuotientAlgorithms#null,
	(opts, I, J) -> (debugInfo(quotient, I, J, strategy); ModuleModuleQuotientAlgorithms#strategy opts)(I, J)))

--------------------------------------------------------------------
-- Saturations
--------------------------------------------------------------------
-- TODO:
-- - should saturate(I) use the irrelevant ideal when multigraded?
-- - should it be cached?

-- saturate = method(Options => options saturate) -- defined in m2/quotient.m2
-- used when P = decompose irr
saturate(Ideal,  List)        := Ideal  => opts -> (I, L) -> fold(L, I, (J, I) -> saturate(I, J, opts))

saturate(Ideal,  Ideal)       := Ideal  => opts -> (I, J) -> saturateHelper(I, J, IdealIdealSaturateAlgorithms, opts)
saturate(Ideal,  RingElement) := Ideal  => opts -> (I, f) -> saturateHelper(I, f, IdealElementSaturateAlgorithms, opts)
saturate Ideal                := Ideal  => opts ->  I     -> saturate(I, ideal vars ring I, opts)

saturate(Module, Ideal)       := Module => opts -> (M, J) -> saturateHelper(M, J, ModuleIdealSaturateAlgorithms, opts)
saturate(Module, RingElement) := Module => opts -> (M, f) -> saturate(M, ideal f, opts)
saturate Module               := Module => opts ->  M     -> saturate(M, ideal vars ring M, opts)
-- TODO: where are these used?
saturate(Vector, Ideal)       := Module => opts -> (v, J) -> saturate(image matrix {v}, J, opts)
saturate(Vector, RingElement) := Module => opts -> (v, f) -> saturate(image matrix {v}, f, opts)
saturate Vector               := Module => opts ->  v     -> saturate(image matrix {v}, opts)

-- Helper for saturation methods
saturateHelper = (A, B, algorithms, opts) -> (
    if (R := ring A) =!= ring B then error "expected objects in the same ring";
    -- TODO: if B \sub A then A:B should be "everything", but this can get slow
    B' := if instance(B, RingElement) then matrix{{B}} else gens B;
    if B == 0 or (target B' == target gens A and B' % gens A == 0) then return ambient A;
    if ambient A == target B' and gens ambient A % B' == 0 then return A;

    strategy := opts.Strategy;
    doTrim := if opts.MinimalGenerators then trim else identity;
    opts = removeOptions(opts, {Strategy, MinimalGenerators});

    C := if strategy === null then runHooks(algorithms#null, (opts, A, B))
    else if algorithms#?strategy then (
	debugInfo(saturate, A, B, strategy);
	(algorithms#strategy opts)(A, B))
    else error("unrecognized Strategy for saturate: '", toString strategy, "'; expected: ", toString keys algorithms);

    if C =!= null then doTrim C else if strategy === null
    then error("no applicable method for saturate(", class A, ", ", class B, ")")
    else error("assumptions for saturation strategy ", toString strategy, " are not met"))

-- Helper for GRevLex strategy
saturationByGRevLexHelper := (I, v, opts) -> (
    R := ring I;
    (R1, fto, fback) := grevLexRing(index v, R);
    g1 := groebnerBasis(fto I, Strategy => "F4");
    (g1', maxpower) := divideByVariable(g1, R1_(numgens R1 - 1));
    (ideal fback g1', maxpower))

-- Algorithms for Module : Ideal^infinity
ModuleIdealSaturateAlgorithms = new HashTable from {
    null    => symbol ModuleIdealSaturateHooks,
    Iterate => opts -> (M, I) -> (
	M' := quotient(M, I, opts); while M' != M do ( M = M'; M' = quotient(M, I, opts)); M ),
    }

-- Installing hooks for Module : Ideal^infinity
scan({Iterate}, strategy -> addHook(ModuleIdealSaturateAlgorithms#null,
	(opts, I, J) -> (debugInfo(saturate, I, J, strategy); ModuleIdealSaturateAlgorithms#strategy opts)(I, J)))

-- Algorithms for Ideal : Ideal^infinity
IdealIdealSaturateAlgorithms = new HashTable from {
    null    => symbol IdealIdealSaturateHooks,
    Iterate => opts -> (I, J) -> (
	-- Iterated quotient
	R := ring I;
	m := transpose generators J;
	while I != 0 do (
	    S := (ring I)/I;
	    m = m ** S;
	    I = ideal syz gb(m, Syzygies => true));
	ideal (presentation ring I ** R)),

    -- TODO: is there a performance hit because neither Eliminate nor Elimination are symbols?
    Eliminate => opts -> (I, J) -> saturate(I, J, opts ++ {Strategy => Elimination}), -- backwards compatibility
    Elimination => opts -> (I, J) -> (
	intersectionByElimination for g in J_* list saturate(I, g, opts)),

    GRevLex => opts -> (I, J) -> (
	-- FIXME: this might not be necessary, but the code isn't designed for this case.
	if not isFlatPolynomialRing ring I
	or not isGRevLexRing ring I then return null;
	-- First check that all generators are variables of the ring
	-- TODO: can this strategy work with generators of the irrelevant ideal?
	if any(index \ J_*, v -> v === null) then return null;
	-- Saturate with respect to each variable separately
	L := for g in J_* list saturationByGRevLexHelper(I, g, opts);
	-- Intersect them all
	-- TODO: when exactly is I returned?
	if any(last \ L, x -> x == 0) then I
	else intersectionByElimination(first \ L)),
    }

-- Installing hooks for Ideal : Ideal^infinity
scan({Iterate, Elimination, GRevLex}, strategy -> addHook(IdealIdealSaturateAlgorithms#null,
	(opts, I, J) -> (debugInfo(saturate, I, J, strategy); IdealIdealSaturateAlgorithms#strategy opts)(I, J)))

-- Algorithms for Ideal : RingElement^infinity
IdealElementSaturateAlgorithms = new HashTable from {
    null   => symbol IdealElementSaturateHooks,
    Iterate => opts -> (I, f) -> saturate(I, ideal f, opts), -- backwards compatibility
    Linear => opts -> (I, f) -> (
	-- assumptions for this case:
	--   (1) the ring is of the form k[x1..xn].  No quotients, k a field or ZZ, grevlex order
	--   (2) all variables have degree 1.
	--   (3) I is homogeneous
	--   (4) f = homog linear form
	R := ring I;
	if not isFlatPolynomialRing R
	or not isGRevLexRing R
	or not isHomogeneous I
	or not isHomogeneous f or not isLinearForm f
	then return null;
	-- TODO: what does this do?
	res := newCoordinateSystem(R, matrix{{f}});
	fto := res#1;
	fback := res#0;
	v := R_(numgens R - 1);
	g := gens gb(fto I, opts);
	ideal fback first divideByVariable(g, v)),

    Bayer => opts -> (I, f) -> (
	-- Bayer method. This may be used if I, f are homogeneous.
	-- Basic idea: in a ring R[z]/(f - z), with the RevLex order, compute GB of I.
	-- assumptions for this case:
	--   (1) the ring is of the form k[x1..xn].  No quotients, k a field or ZZ
	--   (2) J is homogeneous
	--   (3) I = homog, generated by one element
	R := ring I;
	if not isFlatPolynomialRing R
	or not isHomogeneous I
	or not isHomogeneous f
	then return null;
	n := numgens R;
	degs := append(degrees R, degree f);
	X := local X;
	R1 := (coefficientRing R)[X_0 .. X_n, Degrees => degs, MonomialSize => 16];
	i  := map(R1, R, (vars R1)_{0..n-1});
	f1 := i f;
	I1 := ideal (i generators I);
	A  := R1/(f1 - R1_n); -- TODO: add to ideal instead of quotient?
	iback := map(R, A, vars R | f);
	IA := generators I1 ** A;
	g := groebnerBasis(IA, Strategy => "F4"); -- TODO: compare with MGB
	(g1, notused) := divideByVariable(g, A_n);
	ideal iback g1),

    Eliminate => opts -> (I, f) -> saturate(I, f, opts ++ {Strategy => Elimination}), -- backwards compatibility
    Elimination => opts -> (I, f) -> (
	-- Eliminate(t, (I, t * f - 1))
	-- assumptions for this case:
	--  I is an ideal in a flat polynomial ring (ring of the form k[x1..xn], no quotients, k a field or ZZ)
	--  f is an ideal, generated by one elem
	R := ring I;
	if not isFlatPolynomialRing R then return null;
	(R1, fto, fback) := eliminationInfo R;
        J := ideal(R1_0 * fto f - 1) + fto I;
	g := groebnerBasis(J, Strategy => "F4"); -- TODO: compare with MGB
	p1 := selectInSubring(1, g);
	ideal fback p1),

    GRevLex => opts -> (I, v) -> (
	-- FIXME: this might not be necessary, but the code isn't designed for this case.
	if not isFlatPolynomialRing ring I
	or not isGRevLexRing ring I then return null;
	-- First check that v is a variable of the ring
	-- TODO: can this strategy work with generators of the irrelevant ideal?
	if index v === null then return null;
	-- Saturate with respect to each variable separately
	first saturationByGRevLexHelper(I, v, opts)),

    "Unused" => opts -> (I, f) -> (
	-- NOT USED; TODO: assumptions?
	R := ring I;
	I1 := ideal 1_R;
	while I1 != I do (
	    I1 = I;
	    I = ideal syz gb(matrix{{f}} | generators I,
		Syzygies   => true,
                SyzygyRows => 1)
	    );
	I)
    }

-- Installing hooks for Ideal : RingElement^infinity
scan({"Unused", Elimination, GRevLex, Bayer, Linear}, strategy -> addHook(IdealElementSaturateAlgorithms#null,
	(opts, I, J) -> (debugInfo(saturate, I, J, strategy); IdealElementSaturateAlgorithms#strategy opts)(I, J)))

--------------------------------------------------------------------
--------------------------------------------------------------------
----- Input: (M, B) = (Module, Ideal)
----- Output: Returns true if saturate(M, B) == 0 and false otherwise
----- Description: This checks whether the saturation of a module M
----- with respects to an ideal B is zero. This is done by checking
----- whether for each generator of B some power of it annihilates
----- the module M. We do this generator by generator.
--------------------------------------------------------------------
--------------------------------------------------------------------
saturationZero = method()
saturationZero(Ideal,  Ideal) := (I, B) -> saturationZero(comodule I, B)
saturationZero(Module, Ideal) := (M, B) -> (
    Vars := flatten entries vars ring B;
    bGens := flatten entries mingens B;
    for i from 0 to #bGens-1 do (
	b := bGens#i;
	bVars := support b;
	rVars := delete(bVars#1,delete(bVars#0,Vars))|bVars;
	R := coefficientRing ring B [rVars,MonomialOrder=>{Position=>Up,#Vars-2,2}];
	P := sub(presentation M,R);
	G := gb P;
	if (ann coker selectInSubring(1,leadTerm G)) == 0 then return false;
	);
    true)

--------------------------------------------------------------------
----- Tests section
--------------------------------------------------------------------

-- basic tests for quotient
load "./Colon/quotient-test.m2"

-- basic tests for saturate
load "./Colon/saturate-test.m2"

--------------------------------------------------------------------
----- Documentation section
--------------------------------------------------------------------

beginDocumentation()

doc ///
  Key
    Colon
  Headline
    saturation and ideal and submodule colon/quotient routines
--  Description
--    Text
--    Example
--  Caveat
--  SeeAlso
///

-*
Where should these be documented?
quotient
(quotient, MonomialIdeal, MonomialIdeal)
(quotient, MonomialIdeal, RingElement)

saturate
(saturate, MonomialIdeal, MonomialIdeal)
(saturate, MonomialIdeal, RingElement)
*-

-- TODO: review
load "./Colon/quotient-doc.m2"
load "./Colon/saturate-doc.m2"

--------------------------------------------------------------------
----- Development section
--------------------------------------------------------------------

saturationByGRevLex     = (I,J) -> saturate(I, J, Strategy => GRevLex)
saturationByElimination = (I,J) -> saturate(I, J, Strategy => Elimination)

end--

restart
debugLevel = 1
debug needsPackage "Colon"

kk = ZZ/32003
R = kk(monoid[x_0, x_1, x_2, x_3, x_4, Degrees => {2:{1, 0}, 3:{0, 1}}, Heft => {1,1}])
B0 = ideal(x_0,x_1)
B1 = ideal(x_2,x_3,x_4)

I = ideal(x_0^2*x_2^2*x_3^2+44*x_0*x_1*x_2^2*x_3^2+2005*x_1^2*x_2^2*x_3^2+12870
     *x_0^2*x_2*x_3^3-725*x_0*x_1*x_2*x_3^3-15972*x_1^2*x_2*x_3^3-7768*x_0^2*x_2
     ^2*x_3*x_4-13037*x_0*x_1*x_2^2*x_3*x_4-14864*x_1^2*x_2^2*x_3*x_4+194*x_0^2*
     x_2*x_3^2*x_4-2631*x_0*x_1*x_2*x_3^2*x_4-2013*x_1^2*x_2*x_3^2*x_4-15080*x_0
     ^2*x_3^3*x_4-9498*x_0*x_1*x_3^3*x_4+5151*x_1^2*x_3^3*x_4-12401*x_0^2*x_2^2*
     x_4^2+4297*x_0*x_1*x_2^2*x_4^2-13818*x_1^2*x_2^2*x_4^2+7330*x_0^2*x_2*x_3*x
     _4^2-13947*x_0*x_1*x_2*x_3*x_4^2-12602*x_1^2*x_2*x_3*x_4^2-14401*x_0^2*x_3^
     2*x_4^2+8101*x_0*x_1*x_3^2*x_4^2-1534*x_1^2*x_3^2*x_4^2+8981*x_0^2*x_2*x_4^
     3-11590*x_0*x_1*x_2*x_4^3+1584*x_1^2*x_2*x_4^3-13638*x_0^2*x_3*x_4^3-5075*x
     _0*x_1*x_3*x_4^3-14991*x_1^2*x_3*x_4^3,x_0^7*x_2-6571*x_0^6*x_1*x_2+13908*x
     _0^5*x_1^2*x_2+11851*x_0^4*x_1^3*x_2+14671*x_0^3*x_1^4*x_2-14158*x_0^2*x_1^
     5*x_2-15190*x_0*x_1^6*x_2+6020*x_1^7*x_2+5432*x_0^7*x_3-8660*x_0^6*x_1*x_3-
     3681*x_0^5*x_1^2*x_3+11630*x_0^4*x_1^3*x_3-4218*x_0^3*x_1^4*x_3+6881*x_0^2*
     x_1^5*x_3-6685*x_0*x_1^6*x_3+12813*x_1^7*x_3-11966*x_0^7*x_4+7648*x_0^6*x_1
     *x_4-10513*x_0^5*x_1^2*x_4+3537*x_0^4*x_1^3*x_4+2286*x_0^3*x_1^4*x_4+733*x_
     0^2*x_1^5*x_4+11541*x_0*x_1^6*x_4+660*x_1^7*x_4);

--              B0       B1
-- GRevLex      25.95s   0.18s
-- Elimination  28.35s   0.29s
-- Iterate      60.02s   0.05s
for B in {B0, B1} do (
    for strategy in {GRevLex, Elimination, Iterate} do
    print(strategy, (try elapsedTime saturate(I, B, Strategy => strategy);)))

ans1 = elapsedTime saturationByGRevLex(saturationByGRevLex(I, B0), B1); -- 25.53s
ans2 = elapsedTime saturationByGRevLex(saturationByGRevLex(I, B1), B0); -- 22.93s

elapsedTime saturationByGRevLex(I, x_0); -- 9.01s
elapsedTime saturationByGRevLex(I, x_1); -- 8.77s

-- TODO: what a discrepency
ans3 = elapsedTime saturationByElimination(saturationByElimination(I, B0), B1); -- 49.22s
ans4 = elapsedTime saturationByElimination(saturationByElimination(I, B1), B0); -- 28.63


elapsedTime J1 = saturationByElimination(I, x_0);
elapsedTime J2 = saturationByElimination(I, x_1);
elapsedTime J = intersectionByElimination(J1,J2);
elapsedTime J' = intersectionByElimination(J2,J1);
elapsedTime J'' = intersect(J1,J2);
elapsedTime J''' = intersect(J2,J1);
J == J'
J == J''

time gens gb I;
J2 = elapsedTime saturationByElimination(I, x_0);
assert isHomogeneous J2
J2' = elapsedTime saturationByElimination(I, x_1);

J2 = elapsedTime saturationByElimination(I, ideal(x_0,x_1));
J2' = elapsedTime saturationByElimination(J2, ideal(x_2,x_3,x_4));

J1 = elapsedTime saturate(I, x_0);
J1' = elapsedTime saturate(I, x_1);
J1 == J2
J1' == J2'

betti J2
betti J1

restart
load "./Colon/badsaturations.m2"

-- TODO: how was this so fast before??
J = paramRatCurve({2,2},{3,3},{4,2});
elapsedTime genSat(J,2) -- 200 sec
elapsedTime genSat2(J,2) -- 50 sec
elapsedTime genSat3(J,2) -- 35 sec

J = paramRatCurve({2,2},{3,3},{5,2});
elapsedTime genSat(J,2) -- 691 sec
elapsedTime genSat2(J,2) -- 104 sec
elapsedTime genSat3(J,2) -- 71 sec

J = paramRatCurve({2,2},{3,4},{4,3});
elapsedTime genSat(J,2) --  sec
elapsedTime genSat2(J,2) --  sec
elapsedTime genSat3(J,2) -- 75 sec

I = ideal J_*_{5,13}
use ring I
elapsedTime I1 = saturate(I, x_0);
elapsedTime (I2,pow) = saturationByGRevLex(I,x_0);
I1 == I2

elapsedTime I1 = saturate(I, x_1);
elapsedTime (I2,pow) = saturationByGRevLex(I,x_1);
I1 == I2
elapsedTime J1 = intersectionByElimination(I1,I2);

elapsedTime I1 = saturationByGRevLex(I, B0);
elapsedTime I2 = saturationByGRevLex(I1, B1);

elapsedTime saturationByGRevLex(saturationByGRevLex(I, B0), B1);
elapsedTime saturationByGRevLex(saturationByGRevLex(I, B1), B0);

elapsedTime saturationByElimination(saturationByElimination(I, B0), B1);
elapsedTime saturationByElimination(saturationByElimination(I, B1), B0);

elapsedTime J0a = saturationByGRevLex(I,x_0);
elapsedTime J0b = saturationByGRevLex(I,x_1);
--J1 = elapsedTime intersectionByElimination(first J0a,first J0b);
La = elapsedTime trim first J0a;
Lb = elapsedTime trim first J0b;
J1 = elapsedTime intersectionByElimination(La, Lb);
J1a = elapsedTime saturationByGRevLex(J1,x_2);
J1b = elapsedTime saturationByGRevLex(J1,x_3);
J1c = elapsedTime saturationByGRevLex(J1,x_4);
J1a#1, J1b#1, J1c#1
J1ab = elapsedTime intersectionByElimination(J1a,J1b);
elapsedTime J2 = intersectionByElimination{first J1a, first J1b, first J1c};
elapsedTime saturationByGRevLex(I,B0);

saturationByElimination(I,x_0);

(R1,fto,fback) = grevLexRing(0,S)
L = fto I;
satL = ideal first divideByVariable(gens gb L, R1_4);
fback satL
oo == I1
leadTerm oo
ideal oo
(R1,fto,fpack) = grevLexRing(1,S)
use S

R = ZZ/101[a..d]
I = ideal"ab-ac,b2-cd"
I1 = saturate(I,a)
elapsedTime (I2,pow) = saturationByGRevLex(I,a);
I1 == I2
pow
(R1,fto,fback) = grevLexRing(0,R)
fto I
fto

----------------------------
-- Benchmarking example:
restart
needsPackage "Colon"

R = ZZ/101[vars(0..14)]
M = genericMatrix(R, a, 3, 5)
I = minors(3, M);
codim I
d = 4
J = ideal((gens I) * random(R^10, R^d));

-- algorithm; d =   2    3    4    5
-- null          0.45   40
-- Linear         N/A  N/A  N/A  N/A
-- Iterate       0.41   40
-- Quotient        22  271
elapsedTime J'  = quotient(J, I);
for strategy in {Linear, Iterate, Quotient} do
print(strategy, (try (elapsedTime J'  === quotient(J, I, Strategy => strategy)) else "not applicable"))

-- algorithm; d =   2    3    4    5
-- null          0.45  430
-- GRevLex        N/A  N/A  N/A  N/A
-- Elimination   2.87  378
-- Iterate         20  575
elapsedTime J'' = saturate(J, I);
for strategy in {GRevLex, Elimination, Iterate} do
print(strategy, (try (elapsedTime J'' === saturate(J, I, Strategy => strategy)) else "not applicable"))

elapsedTime quotient(J, I, Strategy => Iterate);
elapsedTime saturate(J, I, Strategy => Elimination);

degree I
elapsedTime(J : I_0);
