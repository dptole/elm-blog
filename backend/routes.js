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
      helper.request.log(req, res)

      res.header(
        public_paths.root.headers
      ).file(
        public_paths.root.path
      )
    },

    '/public/*': (req, res) => {
      helper.request.log(req, res)

      const url_path = helper.shouldBe.string(req.__params['*'])

      for(const valid of public_paths.sub)
        if(url_path.startsWith(valid.path))
          return res.header(valid.headers).file(valid.path)

      res.status(404).end('Not found')
    },

    '/tmp': async (req, res) =>
      res.json({
        replies: await db.comments.replies('16e6bb5f6aezh6ndza7dtk') // localhost
      }),

    '/favicon.ico': async (req, res) =>
      res.end(),

    '/me': async (req, res) =>
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

    '/me/avatar': (req, res) =>
      req.authenticate().then(async token =>
        res.json(
          await db.avatars.get(token.user_id)
        )
      ),

    '/sign_out': async (req, res) => {
      // @model sign_out
      const auth_token = req.getCookie(req.cookies.auth_token)
      res.expireCookie(res.cookies.auth_token)
      res.status(200).json({success: auth_token !== null})
    },

    '/tags': async (req, res) =>
      // @model tag[]
      res.json({
        tags: await db.posts.getAllTags()
      }),

    '/me/comments/replies': (req, res) =>
      req.authenticate().then(async token =>
        res.json({
          replies: await db.comments.replies(token.user_id)
        }),
      ),

    '/me/posts': (req, res) =>
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

    '/me/posts/review': (req, res) =>
      req.authenticate().then(async token =>
        res.json({
          posts: await db.posts.getForReview(token.user_id)
        })
      ),

    '/me/posts/review/:post_id': (req, res) =>
      req.authenticate().then(async token =>
        res.json(
          await db.posts.getOneForReview(
            await req.decodeParams(req.paramsDecoders.getOneForReview),
            token.user_id
          )
        )
      ),

    '/me/post/:post_id': (req, res) =>
      // @model post
      req.authenticate().then(async token =>
        res.json({
          post: await db.posts.getOneByAuthorId(
            token.user_id,
            req.__params.post_id
          )
        })
      ),

    '/post/comments/review': (req, res) =>
      // @model comment[]
      req.authenticate().then(async token =>
        res.json(
          await db.comments.getReviews(token.user_id)
        )
      ),

    '/post/comments/review/:comment_id': (req, res) =>
      // @model comment[]
      req.authenticate().then(async token =>
        res.json(
          await db.comments.getReview(
            await req.decodeParams(req.paramsDecoders.getReview),
            token.user_id
          )
        )
      ),

    '/post/comments/review/after/:comment_id': (req, res) =>
      // @model comment[]
      req.authenticate().then(async token =>
        res.todo()
      ),

    '/posts': async (req, res) =>
      // @model published_post[]
      res.json({
        posts: await db.posts.getAllPublished(),
        tags: await db.tags.getAll()
      }),

    '/posts/tag/:tag_id': async (req, res) =>
      // @model published_post[]
      res.json(
        await db.tags.getAllPosts(
          await req.decodeParams(req.paramsDecoders.taggedPost)
        )
      ),

    '/post/:post_id': async (req, res) =>
      // @model published_post
      res.json(
        await db.posts.getAsPublished(req.__params.post_id)
      ),

    '/post/comments/replies/:comment_id': async (req, res) =>
      // @model comment[]
      res.json(
        await db.comments.getReplies(
          await req.decodeParams(req.paramsDecoders.getReplies)
        )
      ),

    '/post/comments/after/:comment_id': async (req, res) =>
      // @model comment[]
      res.json(
        await db.comments.getAfter(
          await req.decodeParams(req.paramsDecoders.getPostCommentsAfter)
        )
      ),

    '/post/:post_id/comments/:page_index': async (req, res) =>
      // @model comment[]
      res.json(
        await db.comments.getPartial(
          await req.decodeParams(req.paramsDecoders.getPostCommentsFraction)
        )
      ),

    '/avatar/:user_id': async (req, res) =>
      res.json(
        await db.avatars.get(
          (await req.decodeParams(req.paramsDecoders.getAvatar)).user_id
        )
      ),

    '/me/graphs/post-stats': (req, res) =>
      req.authenticate().then(async token =>
        res.json(
          await db.graphs.post_stats.get({author_id: token.user_id})
        )
      ),

    '/graphs/post-stats/:author_id': async (req, res) =>
      res.json(
        await db.graphs.post_stats.get(
          await req.decodeParams(
            req.paramsDecoders.getPostGraph
          )
        )
      ),

    '/graphs/post-stats/:post_id/:metric': async (req, res) =>
      res.status(204).empty(
        await db.graphs.post_stats.hit(
          await req.decodeParams(
            req.paramsDecoders.hitPostGraph
          )
        )
      )
  },

  POST: {
    '/sign_up': async (req, res) =>
      res.status(201).json(
        await db.users.signUp(
          await req.decodePayload(req.payloadDecoders.signUp)
        )
      ),

    '/sign_in': async (req, res) => {
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
        '/',
        new Date(token.expires)
      )

      res.status(201).json({user, token})
    },

    '/post/draft': (req, res) =>
      // @model post
      req.authenticate().then(async token =>
        res.status(201).json(
          await db.posts.createDraft(
            await req.decodePayload(req.payloadDecoders.post),
            token.user_id
          )
        )
      ),

    '/post/commit': (req, res) =>
      // @model post
      req.authenticate().then(async token =>
        res.json(
          await db.posts.commitPost(
            await req.decodePayload(req.payloadDecoders.updatePost),
            token.user_id
          )
        )
      ),

    '/post/comment/reply/:comment_id': (req, res) =>
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

    '/post/comment/review/reject/:comment_id': (req, res) =>
      // @model comment
      req.authenticate().then(async token =>
        res.json(
          await db.comments.reject(
            await req.decodeParams(req.paramsDecoders.reject),
            token.user_id
          )
        )
      ),

    '/post/comment/review/publish/:comment_id': (req, res) =>
      // @model comment
      req.authenticate().then(async token =>
        res.json(
          await db.comments.publish(
            await req.decodeParams(req.paramsDecoders.publish),
            token.user_id
          )
        )
      ),

    '/post/comment/:post_id/:page_index': (req, res) =>
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
    '/post/draft': (req, res) =>
      // @model post
      req.authenticate().then(async token =>
        res.json(
          await db.posts.updateDraft(
            await req.decodePayload(req.payloadDecoders.updatePost),
            token.user_id
          )
        )
      ),

    '/post/notes/:post_id': (req, res) =>
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

    '/post/status/:post_id': (req, res) =>
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

    '/me/password': (req, res) =>
      req.authenticate().then(async token =>
        res.json(
          await db.users.updatePassword(
            await req.decodePayload(req.payloadDecoders.updatePassword),
            token.user_id
          )
        )
      ),

    '/me/avatar': (req, res) =>
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
    '/post/:post_id': (req, res) =>
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
