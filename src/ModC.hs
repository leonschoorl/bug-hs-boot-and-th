{-# LANGUAGE TemplateHaskellQuotes #-}
module ModC where

import Language.Haskell.TH
import ModD


someThThingy :: DecsQ
someThThingy = return []
