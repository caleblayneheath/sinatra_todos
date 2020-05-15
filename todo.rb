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
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  
  if @list
    erb :list, layout: :layout
  else
    session[:error] = "The specified list was not found."
    redirect "/lists"
  end
end

# edit existing list
get "/lists/:id/edit" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]

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

def error_for_todo(todo) #, id)
  # todo_names = session[:lists][id][:todos].map { |todo| todo[:name] }

  if !(1..100).cover?(todo.size)
    "Todo must be between 1 and 100 characters."
  # elsif todo_names.include?(todo)
  #   "Todo must be unique"
  end
end

# add a new todo to list
post "/lists/:id/todos" do 
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  todo = params[:todo].strip

  error = error_for_todo(todo) #, id)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: todo, completed: false}
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end

end

# change list properties
post "/lists/:id" do
  list_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout  
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{@list_id}"
  end
end

# deletes list
post "/lists/:id/destroy" do
  @list_id = params[:id].to_i
  session[:lists].delete_at(@list_id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# delete todo from list
post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  
  todo_id = params[:id].to_i
  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@list_id}"
end

# complete/uncomplete todo
post "/lists/:list_id/todos/:id/check" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  
  todo_id = params[:id].to_i
  @list[:todos][todo_id][:completed] = !@list[:todos][todo_id][:completed]
  session[:success] = "#{@list[:todos][todo_id][:completed]}The todo has been updated."
  redirect "/lists/#{@list_id}"
end