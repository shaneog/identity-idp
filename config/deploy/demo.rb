server 'demo.login.gov', roles: %w(web db)
server 'demo-worker.login.gov', roles: %w(app)
set :rails_env, :staging
