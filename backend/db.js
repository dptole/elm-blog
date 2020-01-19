const util = require('util')
const querystring = require('querystring')
const fs = require('fs')
const os = require('os')
const events = require('events')
const db = new events


/*
@model user
  {
    id: string,
    username: string,
    password: string,
    caps: number,
    parent: null | string
  }

@model published_post
  {
    id: string,
    status: enum 'deleted' | 'created'
    tags: string[],
    pages: [
      {kind: 'text', content: string} |
      {kind: 'image', content: url}
    ],
    author: @author
  }
  
@model post
  {
    id: string,
    user_id: string,
    title: string,
    version: number
    pages: [
      {kind: 'text', content: string} |
      {kind: 'image', content: url}
    ],
    tags: string[],
    status: enum 'reviewing' | 'published' | 'draft' | 'deleted',
    notes: string,
    previous_version: null | string
  }

@model author
  {
    id: string,
    username: string
  }

@model token
  {
    id: string,
    user_id: string,
    expires: date
  }

@model auth
  {
    user: @user,
    token: @token
  }

@model sign_out
  {
    success: bool
  }

@model comment
  {
    id: string,
    reply_to_comment_id: maybe string,
    post_id: string,
    page_index: number,
    status: enum 'deleted' | 'created' | 'reviewing',
    created_at: date,
    message: string,
    author: @author
  }

@model tag
  {
    name: string,
    posts: number
  }

*/



module.exports = (helper, server, ql) =>
util._extend(db, {
  CONST: {
    GET_ALL_LIMIT: 10,

    POSTS: {
      DEFAULT_SORT: 'published_at=-1'
    },

    ROOT: {
      USERNAME: 'root'
    },

    SORT: {
      ORDER_SPLIT: '=',
      SORT_GROUP: ','
    }
  },

  errors: (() => {
    const e = {
      // utils
      __UTILS_VALID_CHARS: () =>
        'Valid chars: 0-9, a-z, \\[{(.)}]/+-*%!?_\'"&@$# or comma.',

      // generic
      TOO_MANY_REQUESTS: () => 'Too many requests.',
      INVALID_PAYLOAD: () => 'Invalid payload.',
      ERROR_CREATING_FILE: () => 'Error creating a db file.',
      INVALID_JSON_DECODER: () => 'Invalid JSON decoder.',
      INTERNAL_SERVER_ERROR: () => 'Internal server error.',
      REQUEST_URL_TOO_LONG: () => 'Long URL.',

      // user
      INVALID_AUTHOR_ID: () => 'Invalid author id.',
      INVALID_USER_ID: () => 'Invalid user id.',
      DUPLICATED_USER: () => 'This user already exists.',
      USER_NOT_FOUND: () => 'The user doesn\'t exist.',
      ERROR_READING_ALL_USERS: () => 'Unable to list all users.',
      ERROR_CREATING_USER: () => 'Unable to create a user.',

      INVALID_USER_PASSWORD: () => 'Password must be a 8+ chars string. ' +
        'Valid chars: 0-9, a-z, -, . or _. ' +
        'No spaces allowed.',

      INVALID_USER_USERNAME: () => 'Username must be a non-empty string. ' +
        'Valid chars: 0-9, a-z, -, . or _. ' +
        'No spaces allowed.',

      INVALID_USER_AVATAR: () => 'Invalid avatar file format.',
      ERROR_AVATAR_BAD_HEADER: () => 'Bad avatar format (header).',
      ERROR_AVATAR_BAD_FOOTER: () => 'Bad avatar format (footer).',
      ERROR_AVATAR_NO_COMMANDS: () => 'Avatar with no commands.',
      ERROR_AVATAR_BAD_SQUARE_HEADER: i => '[Square:' + i + ']: Bad header format.',
      ERROR_AVATAR_INVALID_SQUARE_X: i => '[Square:' + i + ']: Invalid X coordinate value.',
      ERROR_AVATAR_INVALID_SQUARE_Y: i => '[Square:' + i + ']: Invalid Y coordinate value.',
      ERROR_AVATAR_INVALID_COLOR_FILLER: i => '[Square:' + i + ']: Bad color filler.',
      ERROR_AVATAR_INVALID_COLOR: i => '[Square:' + i + ']: Bad color.',

      // token / auth
      INVALID_TOKEN: () => 'Invalid token.',
      INVALID_TOKEN_EXPIRED: () => 'Your token has expired.',
      INVALID_CREDENTIALS: () => 'Invalid credentials.',
      POST_TOKEN_ERROR: () => 'Error trying to create a new token.',
      TOKEN_NOT_FOUND: () => 'Token not found.',
      ERROR_DELETING_TOKEN: () => 'Unable to delete this token.',
      DELETE_TOKEN_UNAUTHORIZED: () => 'You can\'t delete this token.',
      INVALID_TOKEN_ID: () => 'Invalid token id.',
      INVALID_TOKEN_EXPIRES: () => 'Invalid token\'s expiration date.',
      INVALID_TOKEN_USER_ID: () => 'Invalid token\'s user id.',

      // json
      INVALID_JSON_PAYLOAD: () => 'The payload is not a valid JSON object.',

      // post
      INVALID_POST_NOTES: () => 'The note must be a non-empty string.',
      INVALID_POST_STATUS: () => 'The status must be either: ' + db.posts.STATUS.listValues(', ', ' or ') + '.',
      ERROR_DELETING_POST: () => 'Unable to delete this post.',
      ERROR_READING_ALL_POSTS: () => 'Unable to list all posts.',
      POST_NOT_FOUND: () => 'Post not found.',
      GET_POST_UNAUTHORIZED: () => 'You can\'t read this post.',
      REVIEW_POST_UNAUTHORIZED: () => 'You can\'t review this post.',
      UPDATE_POST_UNAUTHORIZED: () => 'You can\'t update this post.',
      DELETE_POST_UNAUTHORIZED: () => 'You can\'t delete this post.',
      MAX_DRAFTS_LIMIT: () => 'You can\'t create more drafts at the moment.',
      MAX_COMMITS_LIMIT: () => 'You can\'t send more drafts to review at the moment.',

      UPDATE_POST_COMMIT_INVALID_STATUS: () => 'A post can only be commited ' +
        'when its status is "' + db.posts.STATUS.DRAFT + '" or ' +
        '"' + db.posts.STATUS.CREATED + '".',

      UPDATE_POST_DRAFT_INVALID_STATUS: () => 'Unable to update this post ' +
        'because its status isn\'t "' + db.posts.STATUS.DRAFT + '".',

      INVALID_POST_ID: () => 'Invalid post id.',
      INVALID_PAGE_INDEX: () => 'Invalid page index.',

      INVALID_POST_TITLE: () => 'Title must not be empty. ' +
        e.__UTILS_VALID_CHARS(),

      INVALID_POST_PAGE: () => 'Pages must be either ' +
        'a valid URL [type=image] or ' +
        'a non-empty text [type=text].',

      INVALID_POST_TAGS: () => 'Tags must be a list of non-empty strings. ' +
        e.__UTILS_VALID_CHARS(),

      POST_PAGE_OUT_OF_RANGE: () => 'Page index out of range.',

      // comment
      INVALID_COMMENT_MESSAGE: () => 'Message must be a non-empty string. ' +
        e.__UTILS_VALID_CHARS(),

      COMMENT_REVIEW_PUBLISH_UNAUTHORIZED: () => 'You can\'t publish this comment.',
      COMMENT_REVIEW_REJECT_UNAUTHORIZED: () => 'You can\'t reject this comment.',
      COMMENT_REVIEW_UNAUTHORIZED: () => 'You can\'t review comments.',
      INVALID_COMMENT_ID: () => 'Invalid comment id.',
      COMMENT_NOT_FOUND: () => 'Comment not found.',
      INVALID_COMMENT_POST_ID: () => 'Invalid post id.',
      INVALID_COMMENT_PAGE_INDEX: () => 'Invalid page index.',
      COMMENT_REVIEW_USER_UNAUTHORIZED: () => 'You can\'t review comments from this user.',

      // tags
      TAG_NOT_FOUND: () => 'Tag not found.',

      // graphs
      GRAPH_NOT_FOUND: () => 'The graph doesn\'t exist.',
      INVALID_METRIC_FOR_THIS_GRAPH: () => 'This metric is not valid for this graph.',
      ERROR_READING_ALL_GRAPHS: () => 'Unable to list all graphs.',
      INVALID_DATE_RANGE: () => 'Invalid date range.'
    }

    const errors = {}

    for(const p in e)
      errors[p] = (() => {
        const f = () => ({errors: e[p]()})
        f.string = (...args) => e[p](...args)
        f.throw = (
          status,
          extra = server.errorObject.template.DEFAULT_EXTRA,
          output = server.errorObject.template.DEFAULT_OUTPUT
        ) => 
          server.errorObject
            .create()
            .addError(e[p]())
            .status(status)
            .extra(extra)
            .output(output)
            .throw()
        return f
      })()

    return errors
  })(),

  createDocument: doc =>
    (doc.id = helper.random.dateAndMath(), doc),

  log: (() => {
    const generateLogFilename = () =>
      new Date().toJSON().substr(0, 13)

    let promise = Promise.resolve()

    return async data =>
      promise = promise.catch(console.log).then(async () => {
        const logfile = db.getRequestsPath() + '/' + generateLogFilename()
        fs.appendFileSync(logfile, data + os.EOL)
      })
  })(),

  // ##################################################################
  // USERS
  
  users: {
    get: async username => {
      try {
        return JSON.parse(
          fs.readFileSync(db.getUsersPath() + '/' + username).toString()
        )
      } catch(error) {
        db.errors.USER_NOT_FOUND.throw(404, error)
      }
    },

    signUp: async ({username, password}) => {
      let existing_user = null

      try {
        existing_user = await db.users.get(username)
      } catch(error) {
        helper.warn(
          '/sign_up',
          'Error reading the user ' + username,
          error
        )
      }

      if(existing_user)
        db.errors.DUPLICATED_USER.throw(409)

      const user = await db.users.create({username, password})

      return {user}
    },

    signIn: async ({username, password}) => {
      const user = await db.users.get(username)

      if(user.password !== password)
        db.errors.INVALID_CREDENTIALS.throw(401)

      delete user.password
      const token = await db.tokens.create(user)

      return {
        token,
        user
      }
    },

    isRootDoc: doc =>
      helper.shouldBe.object(doc).username === db.CONST.ROOT.USERNAME,

    isRoot: async user_id =>
      db.users.isRootDoc(
        await db.users.getById(user_id)
      ),

    getChildren: async parent_id =>
      await db.users.getAll(
        ql.createBasicQuery(
          await db.users.isRoot(parent_id)
            ? {}
            : {parent_id}
        ),
        {limit: Infinity}
      ),

    getChild: async (parent_id, child_id) => {
      const children = await db.users.getAll(
        ql.createBasicQuery(
          await db.users.isRoot(parent_id)
            ? {id: child_id}
            : {parent_id, id: child_id}
        ),
        {limit: 1}
      )

      return children.length < 1
        ? null
        : children[0]
    },

    getAll: async (ql, options = {limit: db.CONST.GET_ALL_LIMIT}) => {
      try {
        options = helper.shouldBe.object(options)

        const ls_users = fs.readdirSync(db.getUsersPath())
        const all_users = []

        for(let i = 0; i < ls_users.length; i++) {
          try {
            if(options.limit < 1) break
            const user = await db.users.get(ls_users[i])
            if(!ql || ql.match(user)) {
              options.limit--
              all_users.push(user)
            }
          } catch(error) {
            helper.warn(
              'users.getAll',
              'Error reading the user ' + ls_users[i],
              error
            )
          }
        }

        return all_users
      } catch(error) {
        db.errors.ERROR_READING_ALL_USERS.throw(500, error)
      }
    },

    getById: async user_id => {
      const all_users = await db.users.getAll(
        ql.createBasicQuery({
          id: user_id
        }),
        {
          limit: 1
        }
      )
      const user = all_users[0]

      if(!user)
        db.errors.USER_NOT_FOUND.throw(404)

      return user
    },

    removePassword: user => {
      delete user.password
      return user
    },

    getByIdAsAuthor: async author_id =>
      db.users.removePassword(
        await db.users.getById(author_id)
      ),

    create: async user => {
      try {
        return await db.users.save(db.createDocument(user))
      } catch(error) {
        db.errors.ERROR_CREATING_USER.throw(500, error)
      }
    },

    updatePassword: async ({password}, user_id) => {
      const user = await db.users.getById(user_id)
      user.password = password
      return await db.users.save(user)
    },

    updateAvatar: async ({avatar}, user_id) => {
      const user = await db.users.getById(user_id)
      await db.avatars.upsert(user.id, avatar)
      return await db.users.save(user)
    },

    save: async user =>
      await db.upsertFile(
        db.getUsersPath() + '/' + user.username,
        user
      ).then(() =>
        db.users.get(user.username)
      ).then(db.users.removePassword)
  },

  // ##################################################################
  // GRAPHS

  graphs: {
    post_stats: {
      build: author_id => db.graphs.build(author_id, 'post-stats', ['hit']),

      get: async ({author_id}) =>
        ({
          graphs:
            await db.graphs.post_stats.build(author_id).getRange(
              (new Date).add(-6, 'day'),
              new Date
            )
        }),

      hit: async ({post_id, metric}) => {
        const post = await db.posts.get(post_id)
        const graph = db.graphs.post_stats.build(post.author_id)

        if(!(
          metric in graph.metric &&
          helper.is.func(graph.metric[metric])
        ))
          db.errors.INVALID_METRIC_FOR_THIS_GRAPH.throw(400)

        await graph.metric[metric](post.id).inc()
      }
    },

    build: (author_id, graph_name, metrics) => {
      graph_name = helper.shouldBe.string(graph_name)
      metrics = helper.shouldBe.arrayOfString(metrics)

      const getDate = d =>
        (helper.is.dateObject(d) ? d : new Date()).toJSON().substr(0, 10)

      const getFullGraphName = (post_id, d) =>
        author_id + '-' + post_id + '-' + getDate(d) + '-' + graph_name

      const incMetric = (post_id, metric) => async () => {
        const fgname = getFullGraphName(post_id)
        let g = null

        try {
          g = await db.graphs.get(fgname)
        } catch(_) {
          g = db.createDocument({
            name: fgname,
            date: getDate(),
            metrics: {},
            post_id,
            author_id
          })
        }

        if(!(metric in g.metrics))
          g.metrics[metric] = 0

        g.metrics[metric]++

        await db.graphs.save(g)

        return tools
      }

      const getRange = () => async (from, to) => {
        let to_date = null

        if(!(
          helper.is.dateObject(from) &&
          from.isValid() &&
          helper.is.dateObject(to) &&
          to.isValid() &&
          getDate(from) < (to_date = getDate(to))
        ))
          db.errors.INVALID_DATE_RANGE.throw(400)

        const range = {}
        const post_map = new Map

        const posts = await db.posts.getAllAsPublished(
          ql.createBasicQuery({
            author_id
          }),
          {
            limit: Infinity
          }
        )

        for(const post of posts) {
          post_map.set(post.id, post)

          if(!(post.id in range))
            range[post.id] = {}

          const tmp_from = from.copy()

          while(getDate(tmp_from) <= to_date) {
            const from_date = getDate(tmp_from)

            try {
              const m = (
                await db.graphs.get(
                  getFullGraphName(post.id, tmp_from)
                )
              ).metrics

              range[post.id][from_date] = m
            } catch(error) {
              range[post.id][from_date] = {}
            }

            tmp_from.add(1, 'day')
          }
        }

        for(const post_id of Object.keys(range))
          for(const date of Object.keys(range[post_id]))
            for(const metric_name of metrics)
              if(!(metric_name in range[post_id][date]))
                range[post_id][date][metric_name] = 0

        return Object.keys(range).map(post_id => {
          const post = db.posts.removePages(post_map.get(post_id))

          const m = Object.keys(range[post_id]).map(date => {
            const m = {date}

            for(const metric of metrics)
              m[metric] = range[post_id][date][metric]

            return m
          })

          return {
            post,
            metrics: m
          }
        })
      }

      const tools = {
        getRange: getRange(),

        metric: {}
      }

      for(const metric of metrics)
        tools.metric[metric] = post_id =>
          ({
            inc: incMetric(post_id, metric)
          })

      return tools
    },

    getAll: async (ql, options = {limit: db.CONST.GET_ALL_LIMIT}) => {
      try {
        options = helper.shouldBe.object(options)
        let limit = helper.shouldBe.number(options.limit, db.CONST.GET_ALL_LIMIT)

        const ls_graphs = fs.readdirSync(db.getGraphsPath())
        const all_graphs = []

        for(let i = 0; i < ls_graphs.length; i++) {
          if(limit < 1)
            break

          try {
            const graph = await db.graphs.get(ls_graphs[i])
            if(!ql || ql.match(graph)) {
              limit--
              all_graphs.push(graph)
            }
          } catch(error) {
            helper.warn(
              'graphs.getAll',
              'Error reading the graph ' + ls_graphs[i],
              error
            )
          }
        }

        return all_graphs
      } catch(error) {
        db.errors.ERROR_READING_ALL_GRAPHS.throw(500, error)
      }
    },

    get: async graph_name => {
      try {
        return JSON.parse(
          fs.readFileSync(db.getGraphsPath() + '/' + graph_name).toString()
        )
      } catch(error) {
        db.errors.GRAPH_NOT_FOUND.throw(404, error)
      }
    },

    save: async graph =>
      await db.upsertFile(
        db.getGraphsPath() + '/' + graph.name,
        graph
      ).then(() =>
        db.graphs.get(graph.name)
      )
  },

  // ##################################################################
  // AVATARS

  avatars: {
    get: async user_id => {
      try {
        return JSON.parse(
          fs.readFileSync(db.getAvatarsPath() + '/' + user_id).toString()
        )
      } catch(error) {
        return null
      }
    },

    upsert: async (user_id, avatar) =>
      db.avatars.save(
        db.createDocument({
          user_id,
          avatar
        })
      ),

    save: async avatar =>
      await db.upsertFile(
        db.getAvatarsPath() + '/' + avatar.user_id,
        avatar
      ).then(() =>
        db.avatars.get(avatar.user_id)
      )
  },

  // ##################################################################
  // TOKENS

  tokens: {
    extendExpirationDate: async token => {
      const json = await db.payloadDecoders.token(token)
      json.expires = db.tokens.createExpirationDate()
      return await db.tokens.save(json)
    },

    createExpirationDate: () =>
      new Date().add(1, 'hour'),

    create: async user => {
      const token = db.createDocument({
        user_id: user.id,
        expires: db.tokens.createExpirationDate()
      })

      return await db.tokens.save(token)
    },

    get: async token_id => {
      try {
        return JSON.parse(
          fs.readFileSync(db.getTokensPath() + '/' + token_id).toString()
        )
      } catch(error) {
        db.errors.TOKEN_NOT_FOUND.throw(404, error)
      }
    },

    delete: async (token_id, user_id) => {
      const token = await db.tokens.get(token_id) 

      if(token.user_id !== user_id)
        db.errors.DELETE_TOKEN_UNAUTHORIZED.throw(401)

      try {
        fs.unlinkSync(db.getTokensPath() + '/' + token_id)
        return ''
      } catch(error) {
        db.errors.ERROR_DELETING_TOKEN.throw(500, error)
      }
    },

    save: async token =>
      db.upsertFile(
        db.getTokensPath() + '/' + token.id,
        token
      ).then(() =>
        db.tokens.get(token.id)
      )
  },

  // ##################################################################
  // POSTS

  posts: {
    STATUS: {
      DRAFT: 'draft',
      CREATED: 'created',
      REVIEWING: 'reviewing',
      PUBLISHED: 'published'
    },

    CONSTRAINTS: {
      max_drafts: 3,
      max_created: 3,
      max_reviewing: 3
    },

    getAll: async (ql, options = {limit: db.CONST.GET_ALL_LIMIT, sort: db.CONST.POSTS.DEFAULT_SORT}) => {
      try {
        options = helper.shouldBe.object(options)
        const sort = helper.shouldBe.string(options.sort, db.CONST.POSTS.DEFAULT_SORT)
        let limit = options.limit

        const ls_posts = fs.readdirSync(db.getPostsPath()).reverse()
        const all_posts = []

        for(let i = 0; i < ls_posts.length; i++) {
          if(limit < 1)
            break

          try {
            const post = await db.posts.get(ls_posts[i])
            if(!ql || ql.match(post)) {
              limit--
              all_posts.push(post)
            }
          } catch(error) {
            helper.warn(
              'posts.getAll',
              'Error reading the post ' + ls_posts[i],
              error
            )
          }
        }

        return db.dataManip.create({sort}).transform(all_posts)
      } catch(error) {
        db.errors.ERROR_READING_ALL_POSTS.throw(500, error)
      }
    },

    getAllAsPublished: async ql =>
      db.posts.getAll(ql).then(async posts => {
        const p = []

        for(const post of posts)
          p.push(await db.posts.fromPostToPublished(post))

        return p
      }),

    listAllFromAuthorId: async author_id =>
      (await db.posts.getAll(
        ql.createBasicQuery({
          author_id: author_id,
          //[ql.operator.NEQ('status')]: db.posts.STATUS.REVIEWING
        }),
        {
          limit: Infinity
        }
      )).map(post =>
        db.posts.removePages(post)
      ),

    removePages: post => {
      delete post.pages
      return post
    },

    getAllByAuthorId: async (author_id, options = {status: 0[0]}) => {
      options = helper.shouldBe.object(options)

      const user = await db.users.getById(author_id)

      return await db.posts.getAll(
        ql.createBasicQuery(
          db.posts.STATUS.listValues().includes(options.status)
            ? {status: options.status, author_id: user.id}
            : {author_id: user.id}
        )
      )
    },

    getForReview: async author_id => {
      const user = await db.users.getById(author_id)
      const is_root = await db.users.isRoot(author_id)

      const users = await db.users.getAll(
        ql.createBasicQuery(
          is_root
            ? {}
            : {parent_id: user.id}
        ),
        {
          limit: Infinity
        }
      )

      const all_posts = []

      for(let i = 0; i < users.length; i++) {
        const this_users_posts = await db.posts.getAll(
          ql.createBasicQuery({
            author_id: users[i].id,
            status: db.posts.STATUS.REVIEWING
          })
        )

        all_posts.push(
          ...this_users_posts.map(post => db.posts.removePages(post))
        )
      }

      return all_posts
    },

    getOneByAuthorId: async (author_id, post_id) => {
      const post = await db.posts.get(post_id)
      return post.author_id === author_id
        ? post
        : db.errors.GET_POST_UNAUTHORIZED.throw(401)
    },

    getAsPublished: async post_id => {
      const post = await db.posts.getAll(
        ql.createBasicQuery({
          id: post_id,
          status: db.posts.STATUS.PUBLISHED
        }),
        {
          limit: 1
        }
      )

      if(post.length < 1)
        return null

      return await db.posts.fromPostToPublished(post[0])
    },

    fromPostToPublished: async post => {
      post.author = await db.users.getByIdAsAuthor(post.author_id)
      delete post.author_id
      delete post.notes
      return post
    },

    get: async post_id => {
      try {
        return JSON.parse(
          fs.readFileSync(db.getPostsPath() + '/' + post_id).toString()
        )
      } catch(error) {
        db.errors.POST_NOT_FOUND.throw(404, error)
      }
    },

    canCreateDraft: async author_id => {
      const all_posts = await db.posts.getAllByAuthorId(author_id)
      const all_drafts = all_posts.filter(p =>
        p.status === db.posts.STATUS.DRAFT
      )
      return all_drafts.length < db.posts.CONSTRAINTS.max_drafts
    },

    canSaveDraft: async author_id => {
      const all_created = await db.posts.getAllByAuthorId(
        author_id,
        {
          status: db.posts.STATUS.CREATED
        }
      )

      return all_created.length < db.posts.CONSTRAINTS.max_created
    },

    canCommitPost: async author_id => {
      const all_reviews = await db.posts.getAllByAuthorId(
        author_id,
        {
          status: db.posts.STATUS.REVIEWING
        }
      )

      return all_reviews.length < db.posts.CONSTRAINTS.max_reviewing
    },

    canCreatePost: async author_id =>
      await db.posts.canCreateDraft(author_id) &&
      await db.posts.canCommitPost(author_id),

    createDraft: async (post, author_id) => {
      if(!await db.posts.canCreateDraft(author_id))
        db.errors.MAX_DRAFTS_LIMIT.throw(409)

      db.createDocument(post)

      post.status = db.posts.STATUS.DRAFT
      post.author_id = author_id
      post.tags = post.tags
      post.notes = ''

      return await db.posts.save(post)
    },

    updateDraft: async (post, author_id) => {
      const post_in_db = await db.posts.get(post.id)

      if(post_in_db.status !== db.posts.STATUS.DRAFT)
        db.errors.UPDATE_POST_DRAFT_INVALID_STATUS.throw(409)

      if(post_in_db.author_id !== author_id)
        db.errors.UPDATE_POST_UNAUTHORIZED.throw(401)

      post_in_db.title = post.title
      post_in_db.pages = post.pages
      post_in_db.tags = post.tags

      return await db.posts.save(post_in_db)
    },

    commitPost: async (post, author_id) => {
      const post_in_db = await db.posts.get(post.id)

      if(
        post_in_db.status !== db.posts.STATUS.DRAFT &&
        post_in_db.status !== db.posts.STATUS.CREATED
      )
        db.errors.UPDATE_POST_COMMIT_INVALID_STATUS.throw(409)

      if(post_in_db.author_id !== author_id)
        db.errors.UPDATE_POST_UNAUTHORIZED.throw(401)

      if(
        post_in_db.status === db.posts.STATUS.DRAFT &&
        !await db.posts.canCreateDraft(author_id)
      )
        db.errors.MAX_COMMITS_LIMIT.throw(409)

      if(
        post_in_db.status === db.posts.STATUS.CREATED &&
        !await db.posts.canSaveDraft(author_id)
      )
        db.errors.MAX_COMMITS_LIMIT.throw(409)

      post_in_db.title = post.title
      post_in_db.pages = post.pages
      post_in_db.tags = post.tags
      post_in_db.status = db.posts.STATUS.CREATED

      return await db.posts.save(post_in_db)
    },

    delete: async (post_id, author_id) => {
      const post = await db.posts.get(post_id) 

      if(post.author_id !== author_id)
        db.errors.DELETE_POST_UNAUTHORIZED.throw(401)

      try {
        fs.unlinkSync(db.getPostsPath() + '/' + post.id)
        return ''
      } catch(error) {
        db.errors.ERROR_DELETING_POST.throw(500, error)
      }
    },

    insertNoteOnPost: async ({notes, post_id}, author_id) => {
      const maybe_root = await db.users.getById(author_id)
      const post = await db.posts.get(post_id) 

      if(
        maybe_root.username !== db.CONST.ROOT.USERNAME &&
        post.author_id !== author_id
      )
        db.errors.UPDATE_POST_UNAUTHORIZED.throw(401)

      post.notes = notes

      return await db.posts.save(post)
    },

    updateStatus: async ({status, post_id}, author_id) => {
      const maybe_root = await db.users.getById(author_id)
      const post = await db.posts.get(post_id) 

      if(
        maybe_root.username !== db.CONST.ROOT.USERNAME &&
        post.author_id !== author_id
      )
        db.errors.UPDATE_POST_UNAUTHORIZED.throw(401)

      post.status = status

      if(status === db.posts.STATUS.PUBLISHED) {
        post.published_at = new Date

        /*
        @TODO
        Avoid broken images by copying them from the original host

        post.pages.filter(page => page.kind === 'image')

          [ { content: 'https://osu.ppy.sh/images/layout/pippi.png',
              kind: 'image' },
            { content: 'https://assets.ppy.sh/medals/web/all-secret-obsessed.png',
              kind: 'image' },
            { content: 'https://osu.ppy.sh/images/flags/JP.png',
              kind: 'image' } ]
        */

        for(const tag of post.tags)
          await db.tags.create(tag)
      }

      return await db.posts.save(post)
    },

    getAllPublished: async () => {
      const posts = await db.posts.getAll(
        ql.createBasicQuery({
          status: db.posts.STATUS.PUBLISHED
        }),
        {
          limit: 10
        }
      )
      const published_posts = []

      for(let i = 0; i < posts.length; i++) {
        const post = posts[i]

        try {
          published_posts.push(
            db.posts.removePages(
              await db.posts.fromPostToPublished(post)
            )
          )
        } catch(error) {
          helper.warn('db.posts.getAllPublished', error)
        }
      }

      return published_posts
    },

    getAllPublishedAfter: async ({post_id}) => {
      const posts = await db.posts.getAll(
        ql.createBasicQuery({
          status: db.posts.STATUS.PUBLISHED,
          [ql.operator.LT('id')]: post_id
        }),
        {
          limit: 10
        }
      )
      const published_posts = []

      for(let i = 0; i < posts.length; i++) {
        const post = posts[i]

        try {
          published_posts.push(
            db.posts.removePages(
              await db.posts.fromPostToPublished(post)
            )
          )
        } catch(error) {
          helper.warn('db.posts.getAllPublishedAfter', error)
        }
      }

      return published_posts
    },

    getAllTags: async () => {
      const tags = await db.tags.getAll()
      const post_tags = []

      for(const tag of tags) {
        const posts = await db.posts.getAll(
          ql.createBasicQuery({
            [ql.operator.IN('tags')]: tag.name
          })
        )

        if(posts.length < 1)
          continue

        const last_updated = posts.reduce(
          (last_published_at, post) =>
            last_published_at > post.published_at
              ? last_published_at
              : post.published_at
          , posts[0].published_at
        )

        post_tags.push({
          ...tag,
          last_updated,
          posts: posts.length
        })
      }

      return db.dataManip.create({sort: 'last_updated=-1'}).transform(post_tags)
    },

    getOneForReview: async ({post_id}, user_id) => {
      const post = await db.posts.get(post_id)
      const child = await db.users.getChild(user_id, post.author_id)

      if(!child)
        db.errors.REVIEW_POST_UNAUTHORIZED.throw(403)

      return post
    },

    save: async post =>
      db.upsertFile(
        db.getPostsPath() + '/' + post.id,
        post
      ).then(() =>
        db.posts.get(post.id)
      )
  },

  // ##################################################################
  // COMMENTS

  comments: {
    STATUS: {
      CREATED: 'created',
      REJECTED: 'rejected',
      REVIEWING: 'reviewing'
    },

    get: async comment_id => {
      try {
        return JSON.parse(
          fs.readFileSync(db.getCommentsPath() + '/' + comment_id).toString()
        )
      } catch(error) {
        db.errors.COMMENT_NOT_FOUND.throw(404, error)
      }
    },

    create: async ({message}, {post_id, page_index}, user_id) => {
      const post = await db.posts.get(post_id)
      const author = await db.users.getByIdAsAuthor(user_id)

      if(!(post.pages && post.pages[page_index]))
        db.errors.POST_PAGE_OUT_OF_RANGE.throw(409)

      return await db.comments.save(
        db.createDocument({
          post_id,
          page_index,
          message,
          author,
          reply_to_comment_id: null,
          status: db.users.isRootDoc(author)
            ? db.comments.STATUS.CREATED
            : db.comments.STATUS.REVIEWING,
          created_at: (new Date).toJSON()
        })
      )
    },

    getAll: async (ql, options = {limit: db.CONST.GET_ALL_LIMIT, sort: 0[0]}) => {
      try {
        options = helper.shouldBe.object(options)

        const ls_comments = fs.readdirSync(db.getCommentsPath())
        const all_comments = []

        for(let i = 0; i < ls_comments.length; i++) {
          try {
            if(options.limit < 1) break
            const comment = await db.comments.get(ls_comments[i])
            if(!ql || ql.match(comment)) {
              options.limit--
              all_comments.push(comment)
            }
          } catch(error) {
            helper.warn(
              'comments.getAll',
              'Error reading the comment ' + ls_comments[i],
              error
            )
          }
        }

        return helper.is.string(options.sort)
          ? db.dataManip.create({sort: options.sort}).transform(all_comments)
          : all_comments
      } catch(error) {
        db.errors.ERROR_READING_ALL_POSTS.throw(500, error)
      }
    },

    getPartial: async ({post_id, page_index}) =>
      ({
        comments: await db.comments.getAll(
          ql.createBasicQuery({
            post_id,
            page_index: ql.convert.toInt(page_index),
            status: db.comments.STATUS.CREATED,
            reply_to_comment_id: ql.type.null()
          })
        )
      }),

    getAfter: async ({comment_id}) => {
      const last_comment = await db.comments.get(comment_id)

      return {
        comments: await db.comments.getAll(
          ql.createBasicQuery({
            post_id: last_comment.post_id,
            page_index: ql.convert.toInt(last_comment.page_index),
            [ql.operator.GT('created_at')]: last_comment.created_at,
            reply_to_comment_id: last_comment.reply_to_comment_id || ql.type.null(),
            status: db.comments.STATUS.CREATED
          })
        )
      }
    },

    getReplies: async ({comment_id}) => {
      const last_comment = await db.comments.get(comment_id)

      return {
        comments: await db.comments.getAll(
          ql.createBasicQuery({
            reply_to_comment_id: comment_id,
            status: db.comments.STATUS.CREATED
          })
        )
      }
    },

    reply: async ({message}, {comment_id}, user_id) => {
      const comment = await db.comments.get(comment_id)
      const author = await db.users.getByIdAsAuthor(user_id)

      const reply = db.createDocument({
        message,
        author,
        post_id: comment.post_id,
        page_index: comment.page_index,
        reply_to_comment_id: comment_id,
        status: db.users.isRootDoc(author)
          ? db.comments.STATUS.CREATED
          : db.comments.STATUS.REVIEWING,
        created_at: (new Date).toJSON()
      })

      return await db.comments.save(reply)
    },

    getReviews: async user_id => {
      const parent = await db.users.getById(user_id)
      const review = []
      const children = await db.users.getChildren(parent.id)

      for(let i = 0; i < children.length; i++) {
        const comment = await db.comments.getAll(
          ql.createBasicQuery({
            status: db.comments.STATUS.REVIEWING,
            'author.id': children[i].id
          }),
          {
            limit: Infinity,
            sort: 'created_at=-1'
          }
        )

        review.push(...comment)
      }

      return {
        comments: review
      }
    },

    getReview: async ({comment_id}, user_id) => {
      const child_comment = await db.comments.get(comment_id)

      if(!await db.users.getChild(user_id, child_comment.author.id))
        db.errors.COMMENT_REVIEW_USER_UNAUTHORIZED.throw(401)

      return {
        post: await db.posts.getAsPublished(child_comment.post_id),
        comment: await db.comments.getTreeFromLeaf(child_comment)
      }
    },

    getTreeFromLeaf: async main_comment => {
      const comment_ids = []
      const parent_ids = [main_comment.id]

      const iter = async comment => {
        if(!parent_ids.has() && helper.is.id(comment.reply_to_comment_id)) {
          parent_ids.push(comment.reply_to_comment_id)
          return await iter(await db.comments.get(comment.reply_to_comment_id))
        }

        parent_ids.pop()

        comment.replies = comment.id === main_comment.id
          ? []
          : await iterDown(comment.id)

        return comment
      }

      const iterDown = async comment_id => {
        let replies = []

        if(comment_ids.has(comment_id))
          return replies

        comment_ids.push(comment_id)

        try {
          replies = await db.comments.getAll(
            ql.createBasicQuery({
              id: parent_ids.pop()
            }),
            {
              limit: 1,
              sort: 'created_at=-1'
            }
          )

          for(let i = 0; i < replies.length; i++) {
            replies[i].replies = replies[i].id === main_comment.id
              ? []
              : await iterDown(replies[i].id)
          }

        } catch(error) {}

        return replies
      }

      return await iter(main_comment)
    },

    publish: async ({comment_id}, user_id) => {
      const comment = await db.comments.get(comment_id)
      const child = await db.users.getChild(user_id, comment.author.id)

      if(!child)
        db.errors.COMMENT_REVIEW_PUBLISH_UNAUTHORIZED.throw(401)

      comment.status = db.comments.STATUS.CREATED

      return await db.comments.save(comment)
    },

    reject: async ({comment_id}, user_id) => {
      const comment = await db.comments.get(comment_id)
      const child = await db.users.getChild(user_id, comment.author.id)

      if(!child)
        db.errors.COMMENT_REVIEW_REJECT_UNAUTHORIZED.throw(401)

      comment.status = db.comments.STATUS.REJECTED

      return await db.comments.save(comment)
    },

    replies: async user_id => {
      const user = await db.users.getById(user_id)
      const replies = []
      const m1 = new Map
      const m2 = new Map
      const comment_ids = {}

      const comments = (
        await db.comments.getAll(
          ql.createBasicQuery({
            'author.id': user_id,
            [ql.operator.NEQ('status')]: db.comments.STATUS.REVIEWING
          }),
          {
            limit: Infinity,
            sort: 'created_at=-1'
          }
        )
      ).map(comment => {
        comment_ids[comment.id] = 1
        return comment
      })

      loop: for(const comment of comments) {
        if(!m1.has(comment.post_id))
          m1.set(comment.post_id, new Map)

        if(!m1.get(comment.post_id).has(comment.id))
          m1.get(comment.post_id).set(comment.id, [])

        if(helper.is.id(comment.reply_to_comment_id)) {
          let reply_to_parent = comment

          while(1) {
            const parent = await db.comments.get(reply_to_parent.reply_to_comment_id)

            if(parent.id in comment_ids)
              continue loop

            parent.replies = [reply_to_parent]
            reply_to_parent = parent

            if(!helper.is.id(reply_to_parent.reply_to_comment_id))
              break
          }

          m1.get(comment.post_id).get(comment.id).push(reply_to_parent)
        } else {
          const replies = await db.comments.getTreeFromRoot(comment, comment.author.id)
          if(replies.length > 0) {
            comment.replies = replies
            m1.get(comment.post_id).get(comment.id).push(comment)
          }
        }
      }

      for(const [post_id, m3] of m1.entries()) {
        if(!m2.has(post_id))
          m2.set(
            post_id,
            {
              post: await db.posts.fromPostToPublished(
                await db.posts.get(post_id)
              ),
              comments: []
            }
          )

        for(const [comment_id, comments] of m3.entries()) {
          for(const comment of comments) {
            m2.get(post_id).comments.push(comment)
          }
        }
      }

      return [...m2.values()].filter(p =>
        p.comments.length > 0
      )
    },

    getTreeFromRoot: async (main_comment, author_id = null) => {
      const q = {
        reply_to_comment_id: main_comment.id,
        [ql.operator.NEQ('status')]: db.comments.STATUS.REVIEWING
      }

      if(main_comment.author.id !== author_id)
        q['author.id'] = author_id

      const replies = await db.comments.getAll(
        ql.createBasicQuery(q),
        {
          limit: Infinity
        }
      )

      for(const reply of replies)
        reply.replies = await db.comments.getTreeFromRoot(reply, author_id)

      return replies
    },

    save: async comment =>
      db.upsertFile(
        db.getCommentsPath() + '/' + comment.id,
        comment
      ).then(() =>
        db.comments.get(comment.id)
      )
  },

  // ##################################################################
  // TAGS

  tags: {
    getAllPosts: async ({tag_id}) => {
      const tag = await db.tags.get(tag_id)

      return {
        tag,
        posts: await db.posts.getAllAsPublished(
          ql.createBasicQuery({
            [ql.operator.IN('tags')]: tag.name
          })
        )
      }
    },

    create: async tag_name =>
      await db.tags.getByName(tag_name) ||
      await db.tags.save(
        db.createDocument({
          name: tag_name
        })
      ),

    getByName: async tag_name => {
      const named_tag = await db.tags.getAll(
        ql.createBasicQuery({
          name: tag_name
        })
      )

      if(named_tag.length < 1)
        return null

      return named_tag[0]
    },

    get: async tag_id => {
      try {
        return JSON.parse(
          fs.readFileSync(db.getTagsPath() + '/' + tag_id).toString()
        )
      } catch(error) {
        db.errors.TAG_NOT_FOUND.throw(404, error)
      }
    },

    getAll: async ql => {
      try {
        const ls_tags = fs.readdirSync(db.getTagsPath())
        const all_tags = []

        for(let i = 0; i < ls_tags.length; i++) {
          try {
            const tag = await db.tags.get(ls_tags[i])
            if(!ql || ql.match(tag))
              all_tags.push(tag)
          } catch(error) {
            helper.warn(
              'tags.getAll',
              'Error reading the tag ' + ls_tags[i],
              error
            )
          }
        }

        return all_tags
      } catch(error) {
        db.errors.ERROR_READING_ALL_USERS.throw(500, error)
      }
    },

    save: async tag =>
      db.upsertFile(
        db.getTagsPath() + '/' + tag.id,
        tag
      ).then(() =>
        db.tags.get(tag.id)
      )
  },

  createRootUser: async () => {
    const user = db.payloadDecoders.signUp({
      username: db.CONST.ROOT.USERNAME,
      password: helper.random.dateAndMath()
    })

    if(Array.isArray(user))
      throw user

    try {
      await db.users.get(user.username)
    } catch(error) {
      await db.users.create(user)
    }
  },

  upsertFile: (pathname, file_content) =>
    new Promise((resolve, reject) => {
      const onFinish = () => {
        offError()
        db.ensurePrivileges(pathname)
        resolve()
      }

      const onError = error => {
        offFinish()
        reject(db.errors.ERROR_CREATING_FILE.throw(500, error))
      }

      const offFinish = () => ws.removeListener('finish', onFinish)
      const offError = () => ws.removeListener('error', onError)

      const ws = fs.createWriteStream(pathname)

      ws.once('error', onError)
      ws.once('finish', onFinish)
      ws.end(db.encodeData(file_content))
    }),

  encodeData: data => JSON.stringify(data, 0, 2) + os.EOL,
  decodeData: data => JSON.parse(data),

  getCommentsFolderName: () => 'comments',
  getDbFolderName: () => 'db',
  getUsersFolderName: () => 'users',
  getPostsFolderName: () => 'posts',
  getRequestsFolderName: () => 'requests',
  getTokensFolderName: () => 'tokens',
  getTagsFolderName: () => 'tags',
  getAvatarsFolderName: () => 'avatars',
  getGraphsFolderName: () => 'graphs',

  getDbPath: () => __dirname + '/' + db.getDbFolderName(),
  getUsersPath: () => db.getDbPath() + '/' + db.getUsersFolderName(),
  getPostsPath: () => db.getDbPath() + '/' + db.getPostsFolderName(),
  getRequestsPath: () => db.getDbPath() + '/' + db.getRequestsFolderName(),
  getTokensPath: () => db.getDbPath() + '/' + db.getTokensFolderName(),
  getCommentsPath: () => db.getDbPath() + '/' + db.getCommentsFolderName(),
  getTagsPath: () => db.getDbPath() + '/' + db.getTagsFolderName(),
  getAvatarsPath: () => db.getDbPath() + '/' + db.getAvatarsFolderName(),
  getGraphsPath: () => db.getDbPath() + '/' + db.getGraphsFolderName(),

  ensurePrivileges: path =>
    fs.chmodSync(path, 0777),

  checkup: async () => {
    const db_folder = db.getDbFolderName()
    const posts_folder = db.getPostsFolderName()
    const users_folder = db.getUsersFolderName()
    const requests_folder = db.getRequestsFolderName()

    const root_path = __dirname
    const db_path = db.getDbPath()
    const users_path = db.getUsersPath()
    const posts_path = db.getPostsPath()
    const requests_path = db.getRequestsPath()

    const checkupFolders = (root_path, db_paths, folders_paths) => {
      const ls_root = fs.readdirSync(root_path)

      if(!(
        ls_root && ls_root.length > 0 && ls_root.includes(db_paths[0])
      )) {
        fs.mkdirSync(db_paths[1])
        return callCheckupFolders()
      }

      db.ensurePrivileges(db_paths[1])

      const ls_db = fs.readdirSync(db_paths[1])
      let sub_folders_created = false

      for(let i = 0; i < folders_paths.length; i++) {
        if(!ls_db.includes(folders_paths[i][0])) {
          fs.mkdirSync(folders_paths[i][1])
          return callCheckupFolders()
        }
        sub_folders_created = true
      }

      if(!sub_folders_created)
        throw new Error(`The folder "${db_paths[1]}" is empty`)

      const ui = os.userInfo()
      const db_stat = fs.statSync(db_paths[1])

      if(!(
        db_stat.uid == ui.uid &&
        db_stat.gid == ui.gid
      ))
        throw new Error(
          `The user "${ui.username} must own the folder ${db_paths[1]}`
        )

      for(let i = 0; i < folders_paths.length; i++) {
        const stat = fs.statSync(folders_paths[i][1])

        if(!(
          stat.uid == ui.uid &&
          stat.gid == ui.gid
        ))
          throw new Error(
            `The user "${ui.username} must own the folder ${folders_paths[i][1]}`
          )

        db.ensurePrivileges(folders_paths[i][1])
      }

      return true
    }

    const callCheckupFolders = () =>
      checkupFolders(
        __dirname,
        [
          db.getDbFolderName(), db.getDbPath()
        ],
        [
          [db.getPostsFolderName(), db.getPostsPath()],
          [db.getUsersFolderName(), db.getUsersPath()],
          [db.getRequestsFolderName(), db.getRequestsPath()],
          [db.getTokensFolderName(), db.getTokensPath()],
          [db.getTagsFolderName(), db.getTagsPath()],
          [db.getCommentsFolderName(), db.getCommentsPath()],
          [db.getAvatarsFolderName(), db.getAvatarsPath()],
          [db.getGraphsFolderName(), db.getGraphsPath()]
        ]
      )

    if(callCheckupFolders())
      await db.createRootUser()
    else
      throw new Error('Unable to build db folder structure')
  },

  validate: {
    token: {
      id: {
        test: id =>
          helper.is.id(id)
      },

      user_id: {
        test: user_id =>
          helper.is.nonEmptyString(user_id)
      },

      expires: {
        test: expires =>
          helper.is.string(expires) &&
          new Date(expires).isValid()
      }
    },

    user: {
      id: {
        test: id =>
          helper.is.id(id)
      },

      password: {
        test: password =>
          helper.is.string(password) &&
          password.length >= 8 &&
          helper.regex.iAlpha.test(password)
      },

      username: {
        test: username =>
          helper.is.string(username) &&
          helper.regex.iAlpha.test(username)
      },

      avatar: {
        test: avatar =>
          db.validate.user.avatar.parse(avatar).success,

        commands: {
          square: (avatar, index) => {
            var first_byte = avatar.charCodeAt(0)
            var second_byte = avatar.charCodeAt(1)
            var third_byte = avatar.charCodeAt(2)

            if(!(first_byte >> 4 & 0b1))
              return {
                success: false,
                error: db.errors.ERROR_AVATAR_BAD_SQUARE_HEADER.string(index)
              }

            var flag = first_byte & 0b1111
            var flag_s = flag & 0b11
            var flag_q = flag >> 2

            var x_coord_sign = (flag_s & 0b10) === 0b10 ? -1 : 1
            var y_coord_sign = (flag_s & 0b01) === 0b01 ? -1 : 1

            var quadrant = flag_q === 0b11
              ? 4
              : flag_q === 0b10
              ? 3
              : flag_q === 0b01
              ? 2
              : 1

            var x = second_byte >> 4 & 0b1111
            var y = second_byte & 0b1111

            if(x > 10)
              return {
                success: false,
                error: db.errors.ERROR_AVATAR_INVALID_SQUARE_X.string(index)
              }

            if(y > 10)
              return {
                success: false,
                error: db.errors.ERROR_AVATAR_INVALID_SQUARE_Y.string(index)
              }

            var color = third_byte >> 3 & 0b11111
            var color_filler = third_byte & 0b111

            if(color_filler !== 0)
              return {
                success: false,
                error: db.errors.ERROR_AVATAR_INVALID_COLOR_FILLER.string(index)
              }

            if(color > 22)
              return {
                success: false,
                error: db.errors.ERROR_AVATAR_INVALID_COLOR.string(index)
              }

            return {
              success: true,
              code: avatar.substr(3),
              cmd: 'square',
              x: x * x_coord_sign,
              y: y * y_coord_sign,
              q: quadrant,
              c: color
            }
          }
        },

        parse: avatar => {
          /*
            avatar        := <header> <cmds> <footer>

                              author.language.project.feature.version
            header        := "dptole.elm.blog.avatar.0"

                              one or more commands
            cmds          := [ <square> ] +

                              4 bits
                              b0001 = draw square flag
            square        := b0001 <cmd_flag> <coord_x> <coord_y> <color> <color_filler>

                              4 bits
                              x y sign bits
                              bxx00 = positive coord_x / positive coord_y
                              bxx01 = positive coord_x / negative coord_y
                              bxx10 = negative coord_x / positive coord_y
                              bxx11 = negative coord_x / negative coord_y

                              quadrant bits
                              b00xx = quadrant 1
                              b01xx = quadrant 2
                              b10xx = quadrant 3
                              b11xx = quadrant 4

                              bit ranging from b0000 to b1111
            cmd_flag      := b0000-b1111

                              4 bits
                              b0000 = 0
                              b0001 = 1
                              b0010 = 2
                              b0011 = 3
                              b0100 = 4
                              b0101 = 5
                              b0110 = 6
                              b0111 = 7
                              b1000 = 8
                              b1001 = 9
                              b1010 = 10

                              bits between b1010 and b1111 are invalid
            coord_x       := b0000-b1001
            coord_y       := b0000-b1001

                              5 bits
                              b00000 = rgb(170, 170, 170) | aaaaaa
                              b00001 = rgb(51, 51, 51)    | 333333
                              b00010 = rgb(255, 102, 102) | ff6666
                              b00011 = rgb(255, 201, 102) | ffc966
                              b00100 = rgb(252, 244, 130) | fcf482
                              b00101 = rgb(164, 232, 125) | a4e87d
                              b00110 = rgb(131, 163, 252) | 83a3fc
                              b00111 = rgb(168, 147, 210) | a893d2
                              b01000 = rgb(248, 210, 249) | f8d2f9
                              b01001 = rgb(255, 0, 0)     | ff0000
                              b01010 = rgb(255, 165, 0)   | ffa500
                              b01011 = rgb(255, 255, 0)   | ffff00
                              b01100 = rgb(0, 128, 0)     | 008000
                              b01101 = rgb(0, 0, 255)     | 0000ff
                              b01110 = rgb(75, 0, 130)    | 4b0082
                              b01111 = rgb(238, 130, 238) | ee82ee
                              b10000 = rgb(153, 0, 0)     | 990000
                              b10001 = rgb(150, 86, 3)    | 965603
                              b10010 = rgb(153, 153, 0)   | 999900
                              b10011 = rgb(41, 87, 15)    | 29570f
                              b10100 = rgb(4, 43, 149)    | 042b95
                              b10101 = rgb(44, 30, 72)    | 2c1e48
                              b10110 = rgb(177, 24, 180)  | b118b4
            color         := b00000-b10110

            color_filler  := b000

            footer        := "end"
            
          */
          var header = 'dptole.elm.blog.avatar.WebGL.0'
          var footer = 'end'
          
          if(avatar.substr(0, header.length) !== header)
            return {
              error: db.errors.ERROR_AVATAR_BAD_HEADER.string(),
              success: false
            }

          var cmds = avatar.substr(header.length)
          var cmds_list = []
          var cmd_i = 0

          while(cmds.length > footer.length) {
            var s = db.validate.user.avatar.commands.square(cmds, cmd_i)

            if(!s.success)
              return {
                error: s.error,
                success: false
              }

            cmds = s.code
            delete s.code
            delete s.success
            cmds_list.push(s)

            cmd_i++
          }

          if(cmds !== footer)
            return {
              error: db.errors.ERROR_AVATAR_BAD_FOOTER.string(),
              success: false
            }

          if(cmds_list.length < 1)
            return {
              error: db.errors.ERROR_AVATAR_NO_COMMANDS.string(),
              success: false
            }

          return {
            success: true,
            cmds_list: cmds_list
          }
        }
      }
    },

    post: {
      tags: {
        test: tags =>
          Array.isArray(tags) &&
          tags.every(tag =>
            helper.is.nonEmptyString(tag) &&
            helper.regex.iText.test(tag)
          )
      },

      id: {
        test: id =>
          helper.is.id(id)
      },

      title: {
        test: title =>
          helper.is.nonEmptyString(title) &&
          helper.regex.iText.test(title)
      },

      notes: {
        test: notes =>
          helper.is.nonEmptyString(notes)
      },

      status: {
        test: status =>
          db.posts.STATUS.listValues().includes(status)
      },

      pages: {
        test: async pages => {
          if(!(
            Array.isArray(pages) &&
            pages.length > 0
          ))
            return false

          for(let i = 0; i < pages.length; i++) {
            if(!(
              db.validate.post.pages.text(pages[i]) ||
              await db.validate.post.pages.image(pages[i])
            ))
              return false
          }

          return true
        },

        text: page =>
          helper.is.object(page) &&
          page.kind === 'text' &&
          helper.is.nonEmptyString(page.content),

        image: async page =>
          helper.is.object(page) &&
          page.kind === 'image' &&
          helper.is.nonEmptyString(page.content) &&
          await helper.is.validUrl(page.content)
      }
    },

    comment: {
      id: {
        test: id =>
          helper.is.id(id)
      },

      message: {
        test: message =>
          helper.is.nonEmptyString(message) &&
          helper.regex.iText.test(message)
      },

      page_index: {
        test: page_index =>
          helper.is.string(page_index) &&
          helper.regex.digits.test(page_index)
      },

      post_id: {
        test: post_id =>
          helper.is.id(post_id)
      }
    },

    tag: {
      id: {
        test: id =>
          helper.is.id(id)
      }
    },

    graph: {
      post_id: {
        test: post_id =>
          helper.is.id(post_id)
      },

      author_id: {
        test: author_id =>
          helper.is.id(author_id)
      },

      metric: {
        test: metric =>
          helper.is.nonEmptyString(metric)
      }
    }
  },

  qsDecoders: {
    postReview: async qs => {
      const errors = server.errorObject.create()

      if(!helper.is.object(qs))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.post.status.test(qs.status))
        errors.addFieldError(
          'status',
          db.errors.INVALID_POST_STATUS.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        status: qs.status
      }
    }
  },

  paramsDecoders: {
    createComment: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.comment.post_id.test(params.post_id))
        errors.addFieldError(
          'post_id',
          db.errors.INVALID_COMMENT_POST_ID.string()
        )

      if(!db.validate.comment.page_index.test(params.page_index))
        errors.addFieldError(
          'page_index',
          db.errors.INVALID_COMMENT_PAGE_INDEX.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        post_id: params.post_id,
        page_index: parseInt(params.page_index)
      }
    },

    getPostCommentsFraction: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.comment.post_id.test(params.post_id))
        errors.addFieldError(
          'post_id',
          db.errors.INVALID_POST_ID.string()
        )

      if(!db.validate.comment.page_index.test(params.page_index))
        errors.addFieldError(
          'page_index',
          db.errors.INVALID_PAGE_INDEX.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        post_id: params.post_id,
        page_index: parseInt(params.page_index)
      }
    },

    getPostCommentsAfter: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.comment.id.test(params.comment_id))
        errors.addFieldError(
          'comment_id',
          db.errors.INVALID_COMMENT_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        comment_id: params.comment_id
      }
    },

    reply: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.comment.id.test(params.comment_id))
        errors.addFieldError(
          'comment_id',
          db.errors.INVALID_COMMENT_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        comment_id: params.comment_id
      }
    },

    getReplies: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.comment.id.test(params.comment_id))
        errors.addFieldError(
          'comment_id',
          db.errors.INVALID_COMMENT_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        comment_id: params.comment_id
      }
    },

    getReview: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.comment.id.test(params.comment_id))
        errors.addFieldError(
          'comment_id',
          db.errors.INVALID_COMMENT_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        comment_id: params.comment_id
      }
    },

    publish: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.comment.id.test(params.comment_id))
        errors.addFieldError(
          'comment_id',
          db.errors.INVALID_COMMENT_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        comment_id: params.comment_id
      }
    },

    reject: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.comment.id.test(params.comment_id))
        errors.addFieldError(
          'comment_id',
          db.errors.INVALID_COMMENT_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        comment_id: params.comment_id
      }
    },

    taggedPost: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.tag.id.test(params.tag_id))
        errors.addFieldError(
          'tag_id',
          db.errors.INVALID_COMMENT_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        tag_id: params.tag_id
      }
    },

    getOneForReview: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.post.id.test(params.post_id))
        errors.addFieldError(
          'post_id',
          db.errors.INVALID_POST_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        post_id: params.post_id
      }
    },

    getAvatar: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.user.id.test(params.user_id))
        errors.addFieldError(
          'user_id',
          db.errors.INVALID_USER_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        user_id: params.user_id
      }
    },

    hitPostGraph: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.graph.post_id.test(params.post_id))
        errors.addFieldError(
          'post_id',
          db.errors.INVALID_POST_ID.string()
        )

      if(!db.validate.graph.metric.test(params.metric))
        errors.addFieldError(
          'metric',
          db.errors.INVALID_METRIC_NAME.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        post_id: params.post_id,
        metric: params.metric
      }
    },

    getPostGraph: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.graph.author_id.test(params.author_id))
        errors.addFieldError(
          'author_id',
          db.errors.INVALID_AUTHOR_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        author_id: params.author_id
      }
    },

    getPostsAfter: async params => {
      const errors = server.errorObject.create()

      if(!helper.is.object(params))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.graph.post_id.test(params.post_id))
        errors.addFieldError(
          'post_id',
          db.errors.INVALID_POST_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        post_id: params.post_id
      }
    }
  },

  payloadDecoders: {
    token: json => {
      const errors = server.errorObject.create()

      if(!helper.is.object(json))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.token.id.test(json.id))
        errors.addFieldError(
          'id',
          db.errors.INVALID_TOKEN_ID.string()
        )

      if(!db.validate.token.expires.test(json.expires))
        errors.addFieldError(
          'expires',
          db.errors.INVALID_TOKEN_EXPIRES.string()
        )

      if(!db.validate.token.user_id.test(json.user_id))
        errors.addFieldError(
          'user_id',
          db.errors.INVALID_TOKEN_USER_ID.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        id: json.id,
        expires: json.expires,
        user_id: json.user_id
      }
    },

    signIn: json => {
      const errors = server.errorObject.create()

      if(!helper.is.object(json))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.user.username.test(json.username))
        errors.addFieldError(
          'username',
          db.errors.INVALID_USER_USERNAME.string()
        )

      if(!db.validate.user.password.test(json.password))
        errors.addFieldError(
          'password',
          db.errors.INVALID_USER_PASSWORD.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        username: json.username,
        password: json.password
      }
    },

    signUp: json => {
      const errors = server.errorObject.create()

      if(!helper.is.object(json))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.user.username.test(json.username))
        errors.addFieldError(
          'username',
          db.errors.INVALID_USER_USERNAME.string()
        )

      if(!db.validate.user.password.test(json.password))
        errors.addFieldError(
          'password',
          db.errors.INVALID_USER_PASSWORD.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        username: json.username,
        password: json.password
      }
    },

    post: async json => {
      const errors = server.errorObject.create()

      if(!helper.is.object(json))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.post.title.test(json.title))
        errors.addFieldError(
          'title',
          db.errors.INVALID_POST_TITLE.string()
        )

      if(!db.validate.post.tags.test(json.tags))
        errors.addFieldError(
          'tags',
          db.errors.INVALID_POST_TAGS.string()
        )

      if(!await db.validate.post.pages.test(json.pages))
        errors.addFieldError(
          'pages',
          db.errors.INVALID_POST_PAGE.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        title: json.title,
        tags: json.tags,
        pages: json.pages
      }
    },

    updatePost: async json => {
      const errors = server.errorObject.create()

      if(!helper.is.object(json))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.post.id.test(json.id))
        errors.addFieldError(
          'id',
          db.errors.INVALID_POST_ID.string()
        )

      if(!db.validate.post.tags.test(json.tags))
        errors.addFieldError(
          'tags',
          db.errors.INVALID_POST_TAGS.string()
        )

      if(!db.validate.post.title.test(json.title))
        errors.addFieldError(
          'title',
          db.errors.INVALID_POST_TITLE.string()
        )

      if(!await db.validate.post.pages.test(json.pages))
        errors.addFieldError(
          'pages',
          db.errors.INVALID_POST_PAGE.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        id: json.id,
        title: json.title,
        tags: json.tags,
        pages: json.pages
      }
    },

    insertNoteOnPost: async json => {
      const errors = server.errorObject.create()

      if(!helper.is.object(json))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.post.notes.test(json.notes))
        errors.addFieldError(
          'notes',
          db.errors.INVALID_POST_NOTES.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        notes: json.notes
      }
    },

    updateStatus: async json => {
      const errors = server.errorObject.create()

      if(!helper.is.object(json))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.post.status.test(json.status))
        errors.addFieldError(
          'status',
          db.errors.INVALID_POST_STATUS.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        status: json.status
      }
    },

    createComment: async json => {
      const errors = server.errorObject.create()

      if(!helper.is.object(json))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.comment.message.test(json.message))
        errors.addFieldError(
          'message',
          db.errors.INVALID_COMMENT_MESSAGE.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        message: json.message
      }
    },

    reply: async json => {
      const errors = server.errorObject.create()

      if(!helper.is.object(json))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.comment.message.test(json.message))
        errors.addFieldError(
          'message',
          db.errors.INVALID_COMMENT_MESSAGE.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        message: json.message
      }
    },

    updatePassword: async json => {
      const errors = server.errorObject.create()

      if(!helper.is.object(json))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      if(!db.validate.user.password.test(json.password))
        errors.addFieldError(
          'password',
          db.errors.INVALID_USER_PASSWORD.string()
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        password: json.password
      }
    },

    updateAvatar: async json => {
      const errors = server.errorObject.create()

      if(!helper.is.object(json))
        errors.addError(db.errors.INVALID_PAYLOAD.string())
          .status(400)
          .throw()

      var parsed = db.validate.user.avatar.parse(json.avatar)
      if(!parsed.success)
        errors.addFieldError(
          'avatar',
          parsed.error
        )

      if(errors.has())
        errors.status(400).throw()

      return {
        avatar: json.avatar
      }
    }
  },

  dataManip: {
    // sort BNF
    // sort       := sort_one sort_seq*
    // sort_one   := field "=" sort_order
    // field      := <string>
    // sort_order := "1" | "-1"
    // sort_seq   := ";" sort_one
    sort: (() => {
      const sort = {
        fromString: sort => {
          sort = helper.shouldBe.string(sort)

          const iter = data => {
            const sort_split = sort.split(db.CONST.SORT.SORT_GROUP)

            if(
              data.length < 2 ||
              sort_split.length === 1 &&
              sort_split[0].trim() === ''
            )
              return data

            const [key, order] = sort_split[0].split(db.CONST.SORT.ORDER_SPLIT)
            const order_int = order === '-1' ? -1 : 1
            const map = new Map

            for(let i = 0; i < data.length; i++) {
              const value = helper.accessField(data[i], key)
              if(!map.has(value))
                map.set(value, [])
              map.get(value).push(data[i])
            }

            return [...map.entries()].sort((a,b) =>
              a[0] > b[0] ? order_int : -order_int
            ).reduce((acc, entry) =>
              acc.concat(
                iter(
                  entry[1],
                  sort = sort_split.slice(1).join(db.CONST.SORT.SORT_GROUP)
                )
              ),
              []
            )
          }

          return {
            transform: iter
          }
        }
      }

      Object.defineProperty(sort, 'chain', {
        configurable: false,
        get: () => {
          const sorting = []

          const asc = field => (
            sorting.push(field + db.CONST.SORT.ORDER_SPLIT + '1'),
            chained
          )

          const desc = field => (
            sorting.push(field + db.CONST.SORT.ORDER_SPLIT + '-1'),
            chained
          )

          const transform = data =>
            sort.fromString(sorting.join(db.CONST.SORT.SORT_GROUP)).transform(data)

          const chained = {asc, desc, transform}

          return chained
        }
      })

      return sort
    })(),

    create: ({sort}) => {
      sort = db.dataManip.sort.fromString(sort)
      
      const transform = data => sort.transform(data)

      return {transform}
    }
  }
})

