module Main where

import Streaming as S
import qualified Streaming.Prelude as S

-- import Control.Lens

-- Вывести на экран список list
-- в cols столбцов (например,
-- после каждого числа вывести
-- знак табуляции) и вернуть
-- сумму элементов списка
--
-- > sumAndTabulate 3 [1..10]
-- >
-- >    1       2       3
-- >    4       5       6
-- >    7       8       9
-- >    10
-- >
-- > 55
sumAndTabulate :: Int -> [Int] -> IO Int
sumAndTabulate cols list = error "Write me!"


-- -- Свободная монада - на одном из следующих занятий
-- data S f m r
--   = Elem (f (S f m r)) -- "чистый" элемент e и данные дальше
--   | Act (m (S f m r))  -- данные из действия (в монаде m)
--   | Res r              -- результат r

stS :: Int
    -> Stream (Of Int) IO Int
    -> IO Int
stS cols = fmap S.fst' .
  S.sum .
  S.mapM_ (liftIO . putStrLn) .
  tabS 3 .
  S.copy

-- Получение стрима из нужных строк
tabS :: Monad m
     => Int
     -> Stream (Of Int) m r
     -> Stream (Of String) m r
tabS cols ints = S.mapsM S.mconcat $
                 S.chunksOf cols $
                 S.map addTab ints
  where addTab x = show x ++ "\t"

-- Вывод на экран
outTabS :: Int
        -> Stream (Of Int) IO ()
        -> IO ()
outTabS cols = S.mapM_ putStrLn .
               tabS cols

--------------------------------------

-- data Lens s a = Lens
--   { getter :: s -> a
--   , setter :: s -> (a -> s)
--   }
-- type Lens s a = s -> (a, a -> s)
-- type Lens f s a
--   = (a -> f a) -> s -> f s

ix :: Functor f => Int -> Lens f [a] a
ix k = \mod list -> go mod k list
  where
    go mod 0 (x:xs)
      = (:xs) <$> mod x
    go mod k (x:xs)
      = (x:) <$> go mod (k-1) xs

getter lens s = fst $
  lens (\x -> (x,x)) s
setter lens s y = runIdentity $
  lens (\x -> Identity y) s

ex1 = getter (ix 4) [1..10]
ex2 = setter (ix 4) [1..10] 101
ex3 = ix 4 (\x -> [101..104]) [1..10]

main :: IO ()
main = putStrLn "Hello, Haskell!"