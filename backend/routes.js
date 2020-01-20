const util = require('util')
const events = require('events')
const routes = new events



const public_paths = {
  root: {
    path: 'index.html',
    headers: {
      'content-type': 'text/html; charset=utf-8'
    }
  },
  sub: [{
    path: 'js/elm.min.js',
    headers: {
      'content-type': 'application/javascript; charset=utf-8'
    }
  }]
}


module.exports = (helper, db, server, ql) =>
util._extend(routes, {
  GET: {
    '/': (req, res) => {
      const methods = 'GET POST PUT DELETE'.split(' ')
      const all_routes = {}

      for(const method of methods) {
        all_routes[method] = []

        for(const path in routes[method]) {
          if(path[0] === '/')
            all_routes[method].push(path)
        }
      }

      for(const method of methods)
        all_routes[method].sort()

      res.json({
        routes: all_routes
      })
    },

    '/elm-blog/': (req, res) => {
      helper.request.log(req, res)

      res.setHeader('cache-control', 'max-age=8337601')

      res.header(
        public_paths.root.headers
      ).file(
        public_paths.root.path
      )
    },

    '/elm-blog/public/*': (req, res) => {
      helper.request.log(req, res)

      res.setHeader('cache-control', 'max-age=8337601')

      const url_path = helper.shouldBe.string(req.__params['*'])

      for(const valid of public_paths.sub)
        if(url_path.startsWith(valid.path))
          return res.header(valid.headers).file(valid.path)

      res.status(404).end('Not found')
    },

    '/elm-blog/me': async (req, res) =>
      // @model me
      req.authenticate().then(async token => {
        try {
          const user = await db.users.getById(token.user_id)
          delete user.password
          res.status(200).json({user, token})
        } catch(error) {
          res.expireCookie(res.cookies.auth_token)
            .error(error)
            .errors
            .USER_NOT_FOUND
            .throw(404)
        }
      }),

    '/elm-blog/me/avatar': (req, res) =>
      req.authenticate().then(async token =>
        res.json(
          await db.avatars.get(token.user_id)
        )
      ),

    '/elm-blog/sign_out': async (req, res) => {
      // @model sign_out
      const auth_token = req.getCookie(req.cookies.auth_token)
      res.expireCookie(res.cookies.auth_token)
      res.status(200).json({success: auth_token !== null})
    },

    '/elm-blog/tags': async (req, res) =>
      // @model tag[]
      res.json({
        tags: await db.posts.getAllTags()
      }),

    '/elm-blog/me/comments/replies': (req, res) =>
      req.authenticate().then(async token =>
        res.json({
          replies: await db.comments.replies(token.user_id)
        }),
      ),

    '/elm-blog/me/posts': (req, res) =>
      // @model post[]
      req.authenticate().then(async token =>
        res.json({
          posts:
            helper.is.string(req.__qs.status)
              ? await db.posts.getAllByAuthorId(
                  token.user_id,
                  await req.decodeQs(req.qsDecoders.postReview)
                )
              : await db.posts.listAllFromAuthorId(
                  token.user_id
                )
        })
      ),

    '/elm-blog/me/posts/review': (req, res) =>
      req.authenticate().then(async token =>
        res.json({
          posts: await db.posts.getForReview(token.user_id)
        })
      ),

    '/elm-blog/me/posts/review/:post_id': (req, res) =>
      req.authenticate().then(async token =>
        res.json(
          await db.posts.getOneForReview(
            await req.decodeParams(req.paramsDecoders.getOneForReview),
            token.user_id
          )
        )
      ),

    '/elm-blog/me/post/:post_id': (req, res) =>
      // @model post
      req.authenticate().then(async token =>
        res.json({
          post: await db.posts.getOneByAuthorId(
            token.user_id,
            req.__params.post_id
          )
        })
      ),

    '/elm-blog/post/comments/review': (req, res) =>
      // @model comment[]
      req.authenticate().then(async token =>
        res.json(
          await db.comments.getReviews(token.user_id)
        )
      ),

    '/elm-blog/post/comments/review/:comment_id': (req, res) =>
      // @model comment[]
      req.authenticate().then(async token =>
        res.json(
          await db.comments.getReview(
            await req.decodeParams(req.paramsDecoders.getReview),
            token.user_id
          )
        )
      ),

    '/elm-blog/post/comments/review/after/:comment_id': (req, res) =>
      // @model comment[]
      req.authenticate().then(async token =>
        res.todo()
      ),

    '/elm-blog/posts': async (req, res) =>
      // @model published_post[]
      res.json({
        posts: await db.posts.getAllPublished(),
        tags: await db.tags.getAll()
      }),

    '/elm-blog/posts/after/:post_id': async (req, res) =>
      // @model published_post[]
      res.json({
        posts: await db.posts.getAllPublishedAfter(
          await req.decodeParams(req.paramsDecoders.getPostsAfter)
        )
      }),

    '/elm-blog/posts/tag/:tag_id': async (req, res) =>
      // @model published_post[]
      res.json(
        await db.tags.getAllPosts(
          await req.decodeParams(req.paramsDecoders.taggedPost)
        )
      ),

    '/elm-blog/post/:post_id': async (req, res) =>
      // @model published_post
      res.json(
        await db.posts.getAsPublished(req.__params.post_id)
      ),

    '/elm-blog/post/comments/replies/:comment_id': async (req, res) =>
      // @model comment[]
      res.json(
        await db.comments.getReplies(
          await req.decodeParams(req.paramsDecoders.getReplies)
        )
      ),

    '/elm-blog/post/comments/after/:comment_id': async (req, res) =>
      // @model comment[]
      res.json(
        await db.comments.getAfter(
          await req.decodeParams(req.paramsDecoders.getPostCommentsAfter)
        )
      ),

    '/elm-blog/post/:post_id/comments/:page_index': async (req, res) =>
      // @model comment[]
      res.json(
        await db.comments.getPartial(
          await req.decodeParams(req.paramsDecoders.getPostCommentsFraction)
        )
      ),

    '/elm-blog/avatar/:user_id': async (req, res) =>
      res.json(
        await db.avatars.get(
          (await req.decodeParams(req.paramsDecoders.getAvatar)).user_id
        )
      ),

    '/elm-blog/me/graphs/post-stats': (req, res) =>
      req.authenticate().then(async token =>
        res.json(
          await db.graphs.post_stats.get({author_id: token.user_id})
        )
      ),

    '/elm-blog/graphs/post-stats/:author_id': async (req, res) =>
      res.json(
        await db.graphs.post_stats.get(
          await req.decodeParams(
            req.paramsDecoders.getPostGraph
          )
        )
      ),

    '/elm-blog/graphs/post-stats/:post_id/:metric': async (req, res) =>
      res.status(204).empty(
        await db.graphs.post_stats.hit(
          await req.decodeParams(
            req.paramsDecoders.hitPostGraph
          )
        )
      ),

    '/elm-blog/*': (req, res) => {
      helper.request.log(req, res)

      res.header(
        public_paths.root.headers
      ).file(
        public_paths.root.path
      )
    }
  },

  POST: {
    '/elm-blog/sign_up': async (req, res) =>
      res.status(201).json(
        await db.users.signUp(
          await req.decodePayload(req.payloadDecoders.signUp)
        )
      ),

    '/elm-blog/sign_in': async (req, res) => {
      // @model me
      let params = null

      try {
        params = await req.decodePayload(req.payloadDecoders.signIn)
      } catch(e) {
        db.errors.INVALID_CREDENTIALS.throw(401)
      }

      const {token, user} = await db.users.signIn(params)

      res.setCookie(
        res.cookies.auth_token,
        token.id,
        '/elm-blog/',
        new Date(token.expires)
      )

      res.status(201).json({user, token})
    },

    '/elm-blog/post/draft': (req, res) =>
      // @model post
      req.authenticate().then(async token =>
        res.status(201).json(
          await db.posts.createDraft(
            await req.decodePayload(req.payloadDecoders.post),
            token.user_id
          )
        )
      ),

    '/elm-blog/post/commit': (req, res) =>
      // @model post
      req.authenticate().then(async token =>
        res.json(
          await db.posts.commitPost(
            await req.decodePayload(req.payloadDecoders.updatePost),
            token.user_id
          )
        )
      ),

    '/elm-blog/post/comment/reply/:comment_id': (req, res) =>
      // @model comment
      req.authenticate().then(async token =>
        res.json(
          await db.comments.reply(
            await req.decodePayload(req.payloadDecoders.reply),
            await req.decodeParams(req.paramsDecoders.reply),
            token.user_id
          )
        )
      ),

    '/elm-blog/post/comment/review/reject/:comment_id': (req, res) =>
      // @model comment
      req.authenticate().then(async token =>
        res.json(
          await db.comments.reject(
            await req.decodeParams(req.paramsDecoders.reject),
            token.user_id
          )
        )
      ),

    '/elm-blog/post/comment/review/publish/:comment_id': (req, res) =>
      // @model comment
      req.authenticate().then(async token =>
        res.json(
          await db.comments.publish(
            await req.decodeParams(req.paramsDecoders.publish),
            token.user_id
          )
        )
      ),

    '/elm-blog/post/comment/:post_id/:page_index': (req, res) =>
      // @model comment
      req.authenticate().then(async token =>
        res.json(
          await db.comments.create(
            await req.decodePayload(req.payloadDecoders.createComment),
            await req.decodeParams(req.paramsDecoders.createComment),
            token.user_id
          )
        )
      )
  },

  PUT: {
    '/elm-blog/post/draft': (req, res) =>
      // @model post
      req.authenticate().then(async token =>
        res.json(
          await db.posts.updateDraft(
            await req.decodePayload(req.payloadDecoders.updatePost),
            token.user_id
          )
        )
      ),

    '/elm-blog/post/notes/:post_id': (req, res) =>
      // @model post
      req.authenticate().then(async token =>
        res.json(
          await db.posts.insertNoteOnPost(
            {
              notes: (
                await req.decodePayload(
                  req.payloadDecoders.insertNoteOnPost
                )
              ).notes,
              post_id: req.__params.post_id
            },
            token.user_id
          )
        )
      ),

    '/elm-blog/post/status/:post_id': (req, res) =>
      // @model post
      req.authenticate().then(async token =>
        res.json(
          await db.posts.updateStatus(
            {
              status: (
                await req.decodePayload(
                  req.payloadDecoders.updateStatus
                )
              ).status,
              post_id: req.__params.post_id
            },
            token.user_id
          )
        )
      ),

    '/elm-blog/me/password': (req, res) =>
      req.authenticate().then(async token =>
        res.json(
          await db.users.updatePassword(
            await req.decodePayload(req.payloadDecoders.updatePassword),
            token.user_id
          )
        )
      ),

    '/elm-blog/me/avatar': (req, res) =>
      req.authenticate().then(async token =>
        res.json(
          await db.users.updateAvatar(
            await req.decodePayload(req.payloadDecoders.updateAvatar),
            token.user_id
          )
        )
      )
  },

  DELETE: {
    '/elm-blog/post/:post_id': (req, res) =>
      // @empty
      req.authenticate().then(async token => {
        await db.posts.delete(
          req.__params.post_id,
          token.user_id
        )
        res.status(204).empty()
      })
  }
})
