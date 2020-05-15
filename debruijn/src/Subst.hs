 {-# LANGUAGE TemplateHaskell #-}
module Subst where

import Nat
import Imports

$(singletons [d|

    -- An index: (i.e. just a natural number)
    type Idx = Nat

   -- A substitution algebra
    data Sub a =
       Inc Idx              --  increment by an index amount                
     | a :> Sub a           --  extend a substitution (like cons)
     | Sub a :<> Sub a      --  compose substitutions
        deriving (Eq, Show, Functor) 

    infixr :>     -- like usual cons operator (:)
    infixr :<>    -- like usual composition  (.)
 
    -- identity substitution, leaves all variables alone
    idSub :: Sub a 
    idSub = Inc Z

    -- increment, shifts all variable by one
    incSub :: Sub a 
    incSub = Inc (S Z) 

    -- singleton, replace 0 with t, leave everything
    -- else alone
    singleSub :: a -> Sub a
    singleSub t = t :> idSub

    -- General class for terms that support substitution
    class SubstC a where
       -- variable data constructor
       var   :: Idx -> a 
       -- term traversal
       subst :: Sub a -> a -> a

    --  Value of the index x in the substitution s
    applyS :: SubstC a => Sub a -> Idx -> a
    applyS (Inc k)        x  = var (plus k x)
    applyS (ty :> s)      Z  = ty
    applyS (ty :> s)   (S x) = applyS s x
    applyS (s1 :<> s2)    x  = subst s2 (applyS s1 x)
 
    -- Used in substitution when going under a binder
    lift :: SubstC a => Sub a -> Sub a
    lift s = var Z :> (s :<> incSub)
 
    substList :: SubstC a => Sub a -> [a] -> [a]
    substList s = map (subst s)
 
    incList :: SubstC a => [a] -> [a]
    incList = substList incSub
 
    liftList :: SubstC a => Sub a -> [a] -> [a]
    liftList s = substList (lift s)

 |])


{- NOTE: optimization for above. Won't do it now.
applyS s x | Just f <- isIncN s = var (f x)
isIncN :: Sub a -> Maybe (Nat -> Nat)
isIncN IdS        = Just id
isIncN (Inc :∘ s) = (S .) <$> isIncN s
isIncN _          = Nothing

$(singletons [d|
    liftN :: SubstC a => Nat -> Sub a -> Sub a
    liftN k s = upTo k (s :∘ incN k)
 
    incN :: SubstC a => Nat -> Sub a
    incN Z = IdS
    incN (S n) = (Inc :∘ incN n)

    upTo :: SubstC a => Nat -> Sub a -> Sub a
    upTo Z s     = s
    upTo (S m) s = upTo m (var m :> s)
  |])

-}