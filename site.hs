--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll

import Text.Pandoc (WriterOptions, writerHtml5)

import Control.Applicative (Alternative (..), (<$>))
--------------------------------------------------------------------------------

myFeedConfiguration :: FeedConfiguration
myFeedConfiguration = FeedConfiguration
    { feedTitle       = "Pain is Optional"
    , feedDescription = "Pain treatment using Active Isolated Stretching and Massage Therapy"
    , feedAuthorName  = "Joseph Huang"
    , feedAuthorEmail = "josephshuang@gmail.com"
    , feedRoot        = "http://painisoptional.com"
    }

main :: IO ()
main = hakyll $ do
    match "i/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match (fromList ["about.rst", "policy.markdown"]) $ do
        route   $ setExtension "htm"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.htm" defaultContext
            >>= relativizeUrls

    match "p/*" $ do
        route $ setExtension "htm"
        compile $ pandocCompilerWith defaultHakyllReaderOptions myWriterOptions
            >>= loadAndApplyTemplate "templates/post.htm"    postCtx
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.htm" postCtx
            >>= relativizeUrls

    create ["posts.htm"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "p/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Posts"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.htm" archiveCtx
                >>= loadAndApplyTemplate "templates/default.htm" archiveCtx
                >>= relativizeUrls


    match "index.htm" $ do
        route idRoute
        compile $ do
            let indexCtx = field "post" $ const (itemBody <$> mostRecentPost)
            let homeCtx = constField "title" "Home" `mappend` defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.htm" homeCtx
                >>= relativizeUrls
                
                
                
    match "templates/*" $ compile templateCompiler
    
    create ["atom.xml"] $ do
        route idRoute
        compile $ do
            posts <- fmap (take 10) . recentFirst =<<
                loadAllSnapshots "p/*" "content"
            renderAtom myFeedConfiguration feedCtx posts


--------------------------------------------------------------------------------
postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    dateField "datetime" "%Y-%m-%d" `mappend`
    defaultContext
    
feedCtx :: Context String
feedCtx =
    bodyField "description" `mappend`
    postCtx
    
myWriterOptions :: WriterOptions
myWriterOptions = defaultHakyllWriterOptions
    { writerHtml5 = True
    }
    
mostRecentPost :: Compiler (Item String)
mostRecentPost = head <$> (recentFirst =<< loadAllSnapshots "p/*" "content")
