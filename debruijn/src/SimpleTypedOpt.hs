-- | A version of STLC with a strongly-typed AST
-- Optimized with delayed substitutions
module SimpleTypedOpt where

import Imports
import SubstTypedOpt

-- Same definition of types as in Simple
data Ty = IntTy | Ty :-> Ty
   deriving (Eq,Show)

-- But expression datatype includes a context (g) and type
data Exp :: [Ty] -> Ty -> Type where

 IntE   :: Int -> Exp g IntTy

 VarE   :: Idx g t               -- variable index
        -> Exp g t

 LamE   :: Π t1                  -- type of binder
        -> Bind Exp t1 g t2      -- body of abstraction
        -> Exp g (t1 :-> t2)

 AppE   :: Exp g (t1 :-> t2)     -- function
        -> Exp g t1              -- argument
        -> Exp g t2
 
instance SubstDB Exp where
   var = VarE

   subst s (IntE x)     = IntE x
   subst s (VarE x)     = applySub s x
   subst s (LamE ty e)  = LamE ty (substBind s e)
   subst s (AppE e1 e2) = AppE (subst s e1) (subst s e2)


-----------------------------------------------------------------------
-- Examples

-- | Small-step evaluation of closed terms.
-- 
-- Either return the next term or Nothing, if the term is already a value.
-- Note that the type of this function shows that types are preserved during
-- evaluation
step :: Exp '[] t -> Maybe (Exp '[] t)
step (IntE x)     = Nothing
step (VarE n)     = case n of {}
step (LamE t e)   = Nothing
step (AppE e1 e2) = Just $ stepApp e1 e2 where

    -- Helper function for the AppE case. This function "proves" that we will
    -- *always* take a step if a closed term is an application expression.
    stepApp :: Exp '[] (t1 :-> t2) -> Exp '[] t1  -> Exp '[] t2
    --stepApp (IntE x)       e2 = error "Type error"
    stepApp (VarE n)       e2 = case n of {}    
    stepApp (LamE t e1)    e2 = instantiate e1 e2
    stepApp (AppE e1' e2') e2 = AppE (stepApp e1' e2') e2


-- | Reduce open expressions to their normal form
reduce :: Exp g t -> Exp g t
reduce (IntE x)   = IntE x
reduce (VarE n)   = VarE n
reduce (LamE t e) = LamE t (bind (reduce (unbind e)))
reduce (AppE (LamE t e1) e2)   = subst (single (reduce e2)) (reduce (unbind e1))
-- reduce (AppE (IntE x)    e2)   = error "Type error!"
reduce (AppE e1 e2) = AppE (reduce e1) (reduce e2)
