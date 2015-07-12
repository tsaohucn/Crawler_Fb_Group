require './config/fb_config'

#APP_ID = 'facebook _app_id'
#APP_SECRET = 'facebook_app_secret'

#MONGODB_HOST = '127.0.0.1'
#MONGODB_PORT = 27017
#MONGODB_DBNAME = 'fb_beta'
#MONGODB_USER_NAME = 'username'
#MONGODB_USER_PWD = 'password'

TABLE_PAGES = 'pages' # primary key: page_id
TABLE_POSTS = 'posts' # primary key: post_id
TABLE_COMMENTS = 'comments' # primary key: post_id
TABLE_LIKES = 'likes' # primary key: post_id
TABLE_USERS = 'users' # primary key: fb_id
TABLE_STATISTICS = 'statistics' # primary key: page_id+YYYY-MM
