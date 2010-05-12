{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleContexts #-}
-- | Type classes for returning failures.
module Control.Failure
    ( -- * Type class
      Failure (..)
      -- * Wrapping failures
    , WrapFailure (..)
      -- * Convenience 'String' failure
    , StringException (..)
    , failureString
      -- * Convert 'Failure's into concrete types
    , Try (..)
    , NothingException (..)
    , NullException (..)
    ) where

import Prelude hiding (catch)
import Control.Exception (throw, catch, Exception, SomeException (..))
import Data.Typeable (Typeable)

class Monad f => Failure e f where
    failure :: e -> f v

class Failure e f => WrapFailure e f where
    -- | Wrap the failure value, if any, with the given function. This is
    -- useful in particular when you want all the exceptions returned from a
    -- certain library to be of a certain type, even if they were generated by
    -- a different library.
    wrapFailure :: (forall eIn. Exception eIn => eIn -> e) -> f a -> f a
instance Exception e => WrapFailure e IO where
    wrapFailure f m =
        m `catch` \e@SomeException{} -> throw (f e)

class Try f where
  type Error f
  -- Turn a concrete failure into an abstract failure
  try :: Failure (Error f) f' => f a -> f' a

-- | Call 'failure' with a 'String'.
failureString :: Failure StringException m => String -> m a
failureString = failure . StringException

newtype StringException = StringException String
    deriving Typeable
instance Show StringException where
    show (StringException s) = "StringException: " ++ s
instance Exception StringException

-- --------------
-- base instances
-- --------------

instance Failure e Maybe where failure _ = Nothing
instance Failure e []    where failure _ = []

instance Exception e => Failure e IO where
  failure = Control.Exception.throw

-- not a monad or applicative instance Failure e (Either e) where failure = Left

data NothingException = NothingException
  deriving (Show, Typeable)
instance Exception NothingException

instance Try Maybe where
  type Error Maybe = NothingException
  try Nothing      = failure NothingException
  try (Just x)     = return x

instance Try (Either e) where
  type Error (Either e) = e
  try (Left  e)         = failure e
  try (Right x)         = return x

data NullException = NullException
  deriving (Show, Typeable)
instance Exception NullException

instance Try [] where
  type Error [] = NullException
  try []        = failure NullException
  try (x:_)     = return x
