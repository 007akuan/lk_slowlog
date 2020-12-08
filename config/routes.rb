Rails.application.routes.draw do

  get 'lk_slowlog/index'

  root to: "lk_slowlog#index"
end
