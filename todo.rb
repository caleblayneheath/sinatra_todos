require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

# accessible in both routes and view templates, but should be reserved only for views
helpers do
  def todos_remaining(list)
    list[:todos].reject { |todo| todo[:completed] }.size
  end

  def todos_count(list)
    list[:todos].size
  end

  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining(list) == 0
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todo_class(todo)
    "complete" if todo[:completed]
  end

  def sort_lists(lists, &block)   
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }
    
    incomplete_lists.each { |list| yield(list, lists.index(list)) }
    complete_lists.each { |list| yield(list, lists.index(list)) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }
    
    incomplete_todos.each(&block) #{ |todo| yield(todo, todos.index(todo)) }
    complete_todos.each(&block) #{ |todo| yield(todo, todos.index(todo)) }
  end
end

def load_list(id)
  list = session[:lists].find { |list| list[:id] == id }
  return list if list

  session[:error] = "The specified list was not found."
  redirect "/lists"
end

# return error message if name is invalid, nil if valid
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
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

def next_id(elements)
  max = elements.map { |list| list[:id] }.max
  (max || 0) + 1
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# view all lists
get "/lists" do
  @lists = session[:lists]#.sort_by { |list| list_complete?(list) ? 1 : 0 }
  erb :lists, layout: :layout
end

# render new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# render existing list, based on position in array
get "/lists/:id" do
  id = params[:id].to_i
  @list = load_list(id)
  
  @list_name = @list[:name]
  @list_id = @list[:id]
  @todos = @list[:todos]

  erb :list, layout: :layout
end

# edit existing list
get "/lists/:id/edit" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  erb :edit_list, layout: :layout
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout  
  else
    lists = session[:lists]
    id = next_id(lists)
    lists << {id: id, name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# add a new todo to list
post "/lists/:id/todos" do 
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  text = params[:todo].strip

  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    id = next_id(@list[:todos])
    @list[:todos] << {id: id, name: text, completed: false}
    
    session[:success] = "The todo was added."
    redirect "/lists/#{@list_id}"
  end

end

# change list properties
post "/lists/:id" do
  list_name = params[:list_name].strip
  @list_id = params[:id].to_i
  @list = load_list(@list_id)
  
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
  session[:lists].reject! { |list| list[:id] == @list_id } 
  session[:success] = "The list has been deleted."

  # returns default status of 200
  if env["HTTP_X_REQUESTED_WITH"] == 'XMLHttpRequest'
    "/lists"
  else
    redirect "/lists"
  end
 end

# delete todo from list
post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  
  # todo_id = @list[:todos].index { |todo| todo[:id] == params[:id].to_i }
  # @list[:todos].delete_at(todo_id)

  todo_id = params[:id].to_i
  @list[:todos].reject! { |todo| todo[:id] == todo_id }

  # env is hash containing parts of request,
  # accessing the appropriate header 
  # (which has been standardized with caps, _, and prepended with HTTP)
  if env["HTTP_X_REQUESTED_WITH"] == 'XMLHttpRequest'
    # 204 means successful but no content
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@list_id}"
  end
end

# complete/uncomplete todo
post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  
  todo_id = params[:id].to_i
  is_completed = params[:completed] == 'true'
  todo = @list[:todos].find { |todo| todo[:id] == todo_id }
  todo[:completed] = is_completed

  # todo_id = @list[:todos].index { |todo| todo[:id] == params[:id].to_i }
  # is_completed = params[:completed] == 'true'
  # @list[:todos][todo_id][:completed] = is_completed
  
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list_id}"
end

# complete all todos
post "/lists/:list_id/complete_all" do
  @list_id = params[:list_id].to_i
  @list = load_list(@list_id)
  
  @list[:todos].each do |todo|
    todo[:completed] = true
  end

  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end