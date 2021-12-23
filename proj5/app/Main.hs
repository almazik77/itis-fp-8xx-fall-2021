{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeOperators #-}

module Main where

import Control.Concurrent.STM
import Control.Monad.IO.Class
import Data.Aeson
import Data.Char
import Data.Proxy
import Data.Text (Text)
import qualified Data.Text as T
import GHC.Generics
import Network.HTTP.Client.TLS (newTlsManager)
import Network.Wai.Handler.Warp
import Servant
import Servant.API
import Servant.Client
import Web.HttpApiData
import Data.Aeson.Types (unexpected)

newtype CommaSep a = CommaSep [a]
  deriving (Eq,Show)

instance FromHttpApiData a => FromHttpApiData (CommaSep a) where
  parseUrlPiece t = fmap CommaSep $
                    mapM parseUrlPiece $
                    T.splitOn "," t
  parseQueryParam = fmap CommaSep .
                    mapM parseUrlPiece .
                    T.splitOn ","
instance ToHttpApiData a => ToHttpApiData (CommaSep a) where
  toUrlPiece (CommaSep ts) = T.intercalate "," $ map toUrlPiece ts
  toQueryParam (CommaSep ts) = T.intercalate "," $ map toQueryParam ts

newtype EmptyAny a = EmptyAny (CommaSep a)
  deriving (Eq,Show)

instance FromHttpApiData a => FromHttpApiData (EmptyAny a) where
  parseUrlPiece t = case t of
    "Any" -> pure $ EmptyAny (CommaSep [])
    _ -> EmptyAny <$> parseUrlPiece t
instance ToHttpApiData a => ToHttpApiData (EmptyAny a) where
  toUrlPiece (EmptyAny (CommaSep [])) = "Any"
  toUrlPiece (EmptyAny t) = toUrlPiece t

data Category
  = Programming
  | Misc
  | Dark
  | Pun
  | Spooky
  | Christmas
  deriving (Generic,Eq,Show,Read,Bounded,Enum)

instance FromHttpApiData Category where
  parseUrlPiece = parseBoundedTextData
instance ToHttpApiData Category where
  toUrlPiece = T.pack . show
instance FromJSON Category
instance ToJSON Category where
  toEncoding = genericToEncoding defaultOptions

type Categories = EmptyAny Category

data Lang = Cs | De | En | Es | Fr | Pt
  deriving (Generic,Eq,Show,Read,Bounded,Enum)

instance FromHttpApiData Lang where
  parseUrlPiece = parseBoundedTextData
instance ToHttpApiData Lang where
  toUrlPiece = T.toLower . T.pack . show
instance FromJSON Lang where
  parseJSON = genericParseJSON $
    defaultOptions { constructorTagModifier = map toLower }

data Flag
  = Nsfw
  | Religious
  | Political
  | Racist
  | Sexist
  | Explicit
  deriving (Eq,Show,Read,Bounded,Enum)

instance FromHttpApiData Flag where
  parseUrlPiece = parseBoundedTextData
instance ToHttpApiData Flag where
  toUrlPiece = T.toLower . T.pack . show

type Flags = CommaSep Flag

data JokeType = Single | Twopart
  deriving (Eq,Show,Read,Bounded,Enum)

instance FromHttpApiData JokeType where
  parseUrlPiece = parseBoundedTextData
instance ToHttpApiData JokeType where
  toUrlPiece = T.toLower . T.pack . show

data Range = Range
  { from :: Int
  , to :: Int
  }
  deriving (Eq,Show)

instance FromHttpApiData Range where
  parseQueryParam t = do
    let ts = T.splitOn "-" t
    ints <- mapM parseQueryParam ts
    case ints of
      [f,t] -> pure $ Range f t
      _ -> Left "Wrong number of components in range"
instance ToHttpApiData Range where
  toQueryParam (Range f t) = T.concat
    [ T.pack $ show f, "-", T.pack $ show t]

data JokeFlags = JokeFlags
  { nsfw :: Bool
  , religious :: Bool
  , political :: Bool
  , racist :: Bool
  , sexist :: Bool
  , explicit :: Bool
  } deriving (Generic,Eq,Show)
instance FromJSON JokeFlags

data JokeContents
  = JokeSingle { joke :: Text }
  | JokeTwopart { setup :: Text, delivery :: Text }
  deriving (Generic,Eq,Show)

data Joke = Joke
  { error :: Bool
  , category :: Category
  , contents :: JokeContents
  , flags :: JokeFlags
  , safe :: Bool
  , id :: Int
  , lang :: Lang
  }
  deriving (Generic,Eq,Show)
instance FromJSON Joke where
  parseJSON = withObject "Joke" $ \obj -> do
    type_ <- obj .: "type"
    contents <- case (type_ :: Text) of
      "single" -> JokeSingle <$> obj .: "joke"
      "twopart" -> JokeTwopart <$> obj .: "setup" <*> obj .: "delivery"
      _ -> unexpected "Unexpected type"
    err <- obj .: "error"
    cat <- obj .: "category"
    flags <- obj .: "flags"
    safe <- obj .: "safe"
    id <- obj .: "id"
    lang <- obj .: "lang"
    pure $ Joke err cat contents flags safe id lang

type JokeApi
  = "joke"
  :> Capture "category" Categories
  :> QueryParam "lang" Lang
  :> QueryParam "blacklistFlags" Flags
  :> QueryParam "type" JokeType
  :> QueryParam "contains" Text
  :> QueryParam "idRange" Range
  :> Get '[JSON] Joke

api :: Proxy JokeApi
api = Proxy

getJoke :: Categories
     -> Maybe Lang
     -> Maybe Flags
     -> Maybe JokeType
     -> Maybe Text
     -> Maybe Range
     -> ClientM Joke
getJoke = client api

runJokeApi :: ClientM a -> IO (Either String a)
runJokeApi actions = do
  mgr <- newTlsManager
  let env = mkClientEnv mgr $
        BaseUrl Https "v2.jokeapi.dev" 443 ""
  res <- runClientM actions env
  case res of
    Left err -> print err >> pure (Left $ show err)
    Right a -> pure $ Right a



data Task = Task
  { description :: Text
  , finished :: Bool
  } deriving (Generic,Eq,Show)
instance FromJSON Task
instance ToJSON Task where
  toEncoding = genericToEncoding defaultOptions


type TodoApi
  =      "tasks" :> QueryParam "finished" Bool :> Get '[JSON] [(Int,Task)]
    :<|> "tasks" :> ReqBody '[JSON] Task :> Post '[JSON] Int
    :<|> "tasks" :> Capture "taskId" Int :> Get '[JSON] Task
    :<|> "tasks" :> Capture "taskId" Int :> DeleteNoContent

server :: TVar [Task] -> Server TodoApi
server store
  =    getTasks store
  :<|> postTask store
  :<|> getTask store
  :<|> finishTask store

getTasks :: TVar [Task] -> Maybe Bool -> Handler [(Int,Task)]
getTasks store mfin = do
  tasks <- liftIO $ atomically $ zip [0..] <$> readTVar store
  case mfin of
    Nothing -> pure tasks
    Just fin -> pure $ filter ((==fin) . finished . snd) tasks

postTask :: TVar [Task] -> Task -> Handler Int
postTask store task = liftIO $ atomically $ do
  modifyTVar' store (++[task])
  pred . length <$> readTVar store

getTask :: TVar [Task] -> Int -> Handler Task
getTask store k = liftIO $ atomically $ (!!k) <$> readTVar store

finishTask :: TVar [Task] -> Int -> Handler NoContent
finishTask store k = liftIO $ atomically $ do
  modifyTVar' store $ \tasks ->
    take k tasks ++ [(tasks!!k) { finished = True }] ++ drop (k+1) tasks
  pure NoContent

main :: IO ()
main = do
  r <- runJokeApi $ do
    x <- getJoke (EmptyAny (CommaSep [])) Nothing Nothing Nothing Nothing Nothing
    y <- getJoke (EmptyAny (CommaSep [Programming])) Nothing Nothing Nothing Nothing Nothing
    z <- getJoke (EmptyAny (CommaSep [])) (Just De) Nothing Nothing Nothing Nothing
    pure [x,y,z]
  print r
  -- Serving API
  store <- newTVarIO []
  run 8081 $ serve (Proxy :: Proxy TodoApi) $ server store
