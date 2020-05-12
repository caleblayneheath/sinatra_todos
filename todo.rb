require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

=begin
these URLs are resouce based, lists is the name of a resource being worked with
GET /lists
GET /lists/new
POST /lists
GET /lists/1

example
GET /users
GET /users/1
=end

get "/" do
  redirect "/lists"
end

# view all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# render new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# render existing list, based on position in array
get "/lists/:id" do
  id = params[:id].to_i
  @list = session[:lists][id]
  
  #redirect "/lists" unless @list

  erb :list, layout: :layout
end

# edit existing list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]

  erb :edit_list, layout: :layout
end

# return error message if name is invalid, nil if valid
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout  
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# create todo
post "/list/:id" do
  todo_name = params[:todo_name]
  
  id = params[:id].to_i
  list = session[:lists][id]
  list[:todos] << todo_name

  redirect "/lists/#{id}"
end

# change list properties
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = session[:lists][id]
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout  
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end
end

# deletes list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end