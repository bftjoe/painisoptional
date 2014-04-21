--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll


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

    match (fromList ["about.rst"]) $ do
        route   $ setExtension "htm"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.htm" defaultContext
            >>= relativizeUrls

    match "p/*" $ do
        route $ setExtension "htm"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.htm"    postCtx
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/default.htm" postCtx
            >>= relativizeUrls

    create ["archive.htm"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "p/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.htm" archiveCtx
                >>= loadAndApplyTemplate "templates/default.htm" archiveCtx
                >>= relativizeUrls


    match "index.htm" $ do                                                                                                                              
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "p/*"
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Home"                `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.htm" indexCtx
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
    defaultContext
    
feedCtx :: Context String
feedCtx =
    bodyField "description" `mappend`
    postCtx
