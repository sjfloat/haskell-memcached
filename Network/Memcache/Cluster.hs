module Network.Memcache.Cluster (
    Cluster(..),
    Distribute,
    simple
) where

import Network.Memcache.Server
import Network.Memcache.Key
import Network.Memcache.Memcache
import qualified Network.Memcache.Protocol as P

import Data.List (foldl')

data Cluster =
  Cluster {
    servers :: [Server AutoConnection],
    distribute :: Distribute
  }

type Distribute = [Server AutoConnection] -> String -> Server AutoConnection

-- TODO: ketama (requires an MD5 library)
-- Reference: http://www.last.fm/user/RJ/journal/2007/04/10/rz_libketama_-_a_consistent_hashing_algo_for_memcache_clients
-- ketama :: String -> [Server NoConnection] -> Server NoConnection
-- ketama k (s : ss) = s -- temporary: get first

-- this seems ok for short keys
-- TODO: prevent empty list of servers from getting here
simple :: String -> [Server AutoConnection] -> Server AutoConnection
simple k (s : []) = s
simple k ss       = head . snd $ splitAt idx ss
  where
    hash = foldl' (\c i -> i + c * 31) 0 . map fromEnum
    idx = (hash . toKey) k `mod` length ss

instance Memcache Cluster where
  get cl k     = get (getServer cl k) k
  delete cl k  = delete (getServer cl k) k
  set cl k     = set (getServer cl k) k
  add cl k     = add (getServer cl k) k
  replace cl k = replace (getServer cl k) k
  incr cl k    = incr (getServer cl k) k
  decr cl k    = decr (getServer cl k) k

getServer cl key = distribute cl (servers cl) (toKey key)