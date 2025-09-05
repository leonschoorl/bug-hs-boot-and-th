module ModC where

import ModD

someThThingy :: Monad m => m [a]
-- ^ would normally be: Q [Dec]
-- But with this more generic type, we don't have to depend on template-haskell
someThThingy = return []
