module PFQDaemon where

import Config

import Network.PFq.Lang
import Network.PFq.Default
import Network.PFq.Experimental

config =
    [
        Group
        { policy    = Restricted
        , gid       = 1
        , input     = [ dev "ens3" ]
        , function  = ip >-> steer_flow
        }
    ]
