After (knowingly) adding a import loop to a complex project and (thinking I'd fixed it by adding an appropriate .hs-boot file) ghc came back to me with:
`getLinkDeps: Home module not loaded ModB`

Which was very confusing because I didn't modify `ModB`, nor the module that imported `ModB`.
After much simplification I was able to narrow it down to:

ModZ.hs:
```haskell
module ModZ where
import ModB
```

ModZ.hs-boot:
```haskell
module ModZ where
```

ModB.hs:
```haskell
{-# LANGUAGE TemplateHaskell #-}
module ModB where
import ModC

someThThingy
```

ModC.hs:
```haskell
module ModC where
import ModD

someThThingy :: Monad m => m [a]
-- ^ would normally be: Q [Dec]
-- But with this more generic type, we don't have to depend on template-haskell
someThThingy = return []
```

ModD.hs:
```haskell
module ModD where

import {-# SOURCE #-} ModZ
```

Since ghc-9.4 and up until ghc-9.12.2 the error is:
```
<no location info>: error:
    getLinkDeps: Home module not loaded ModB hs-boot-and-th-0.1.0.0-inplace
```

Interestingly with older versions (ghc-8.10 - ghc-9.2) the error is different, a somewhat more helpful:
```
<no location info>: error:
    module ModZ cannot be linked; it is only available as a boot module
```

When I rename `ModZ` to `ModA` in the example above, I get the same `cannot be linked; it is only available as a boot module` on all versions.



Manually copying the imports from ModZ.hs to ModZ.hs-boot kind of shows what's going on:
```
Module graph contains a cycle:
        module ‘ModZ’ (src/ModZ.hs-boot)
        imports module ‘ModB’ (src/ModB.hs)
  which imports module ‘ModC’ (src/ModC.hs)
  which imports module ‘ModD’ (src/ModD.hs)
  which imports module ‘ModZ’ (src/ModZ.hs-boot)
```



What I now understand to be going on is something like this:
```
Module graph contains a cycle:
        module ‘ModZ’ (src/ModZ.hs)
        imports module ‘ModB’ (src/ModB.hs)
  which imports module ‘ModC’ (src/ModC.hs)
  which loads (because TH) module ‘ModD’ (src/ModD.hs)
  which loads (because TH) module ‘ModZ’ (src/ModZ.hs) (even though it only imports src/ModZ.hs-boot)
```
