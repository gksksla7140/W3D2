require 'sqlite3'
require 'singleton'

class QuestionDatabase < SQLite3::Database
  include Singleton 
  
  def initialize 
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end 
end

class User
  attr_accessor :fname, :lname

  def self.all 
    users = QuestionDatabase.instance.execute("SELECT * FROM users")
    users.map {|data| User.new(data)}
  end 
  
  
  def self.find_by_id(id)
    user = QuestionDatabase.instance.execute(<<-SQL, id) 
    SELECT 
    *
    FROM 
    users
    WHERE 
    id = ?
    SQL
    return nil if user.length < 0
    User.new(user.first)
  end 
  
  def self.find_by_name(fname, lname)
    users = QuestionDatabase.instance.execute(<<-SQL, fname, lname) 
    SELECT 
    *
    FROM 
    users
    WHERE 
    fname = ? AND lname = ?
    SQL
    return nil if users.length < 0
    users.map {|data| User.new(data)}
  end
  
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end 
  
  def create
    raise "#{self} already in databse" if @id 
    QuestionDatabase.instance.execute(<<-SQL, @fname, @lname)
     INSERT INTO 
      users (fname, lname)
     VALUES  
      (?,?)
    SQL
    @id = QuestionDatabase.instance.last_insert_row_id 
  end 
  
  def update 
    raise "#{self} is not created" unless @id 
    QuestionDatabase.instance.execute(<<-SQL, @fname,@lname, @id )
    UPDATE 
      users
    SET 
      fname =?  , lname = ?
    WHERE 
      id = ?
    SQL
  end
  
  def authored_questions
    raise "#{self} is not an author" unless @id 
    questions = QuestionDatabase.instance.execute(<<-SQL, @id) 
      SELECT 
        *
      FROM 
        questions
      WHERE 
        author_id = ?
      SQL
    return nil if questions.length <= 0
    questions.map {|data| Question.new(data)}
  end 
  
  def authored_replies
    raise "#{self} is not an author" unless @id 
    replies = QuestionDatabase.instance.execute(<<-SQL, @id) 
      SELECT 
        *
      FROM 
        replies
      WHERE 
        author_id = ?
      SQL
    return nil if replies.length <= 0
    replies.map {|data| Reply.new(data)}
  end 
  
  def followed_questions 
    QuestionFollow.followed_questions_for_user_id(@id)
  end
  
  def liked_questions 
    QuestionLike.liked_questions_for_user_id(@id)
    
  end
  
end 

class Question 
  attr_accessor :title, :author_id, :body 
  
  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end
  
  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)  
  end
  
  def self.all 
    questions = QuestionDatabase.instance.execute("SELECT * FROM questions")
    questions.map {|data| Question.new(data)}
  end 
  
  def self.find_by_id(id)
    question = QuestionDatabase.instance.execute(<<-SQL, id) 
      SELECT 
        *
      FROM 
        questions
      WHERE 
        id = ?
      SQL
    return nil if question.length <= 0
    Question.new(question.first)
  end 
  
  def self.find_by_author_id(author_id)
    question = QuestionDatabase.instance.execute(<<-SQL, author_id) 
    SELECT  
      *
    FROM 
      questions
    WHERE 
      author_id = ?
    SQL
    return nil if question.length < 0
    Question.new(question.first)
  end 
  
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end 
  
  def create
    raise "#{self} already in databse" if @id 
    QuestionDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
     INSERT INTO 
      questions (title,body,author_id)
     VALUES  
      (?,?,?)
    SQL
    @id = QuestionDatabase.instance.last_insert_row_id 
  end 
  
  def update 
    raise "#{self} is not created" unless @id 
    QuestionDatabase.instance.execute(<<-SQL, @title, @body, @author_id , @id)
    UPDATE 
      questions
    SET 
      title = ?, body = ?, author_id = ?
    WHERE 
      id = ?
      
    SQL
  end
  
  def author 
    author = QuestionDatabase.instance.execute(<<-SQL, @author_id) 
      SELECT 
        *
      FROM 
        users
      WHERE 
        id = ?
      SQL
    
    User.new(author.first)
  end
    
  def replies 
    replies = QuestionDatabase.instance.execute(<<-SQL, @id) 
      SELECT 
        *
      FROM 
        replies
      WHERE 
        question_id = ? 
      SQL
    return nil if replies.length <= 0
    replies.map {|data| Reply.new(data)}
  end 
  
  def followers
    QuestionFollow.followers_for_question_id(@id)
  end
  
  def likers 
    QuestionLike.likers_for_questions(@id)
  end
  
  def num_likes 
    QuestionLike.num_likes_for_question_id(@id)
    
  end
  
end 


class Reply 

  
  def self.find_by_id(id)
    reply = QuestionDatabase.instance.execute(<<-SQL, id) 
      SELECT 
        *
      FROM 
        replies
      WHERE 
        id = ?
      SQL
    return nil if reply.length <= 0
    Reply.new(reply.first)
  end 
  
  def self.find_by_user_id(user_id)
    replies = QuestionDatabase.instance.execute(<<-SQL, user_id) 
      SELECT 
        *
      FROM 
        replies
      WHERE 
        author_id = ?
      SQL
    return nil if replies.length <= 0
    replies.map {|data| Reply.new(data)}
  end 
  
  def self.find_by_question_id(ques_id)
    replies = QuestionDatabase.instance.execute(<<-SQL, ques_id) 
      SELECT 
        *
      FROM 
        replies
      WHERE 
        question_id = ? 
      SQL
    return nil if replies.length <= 0
    replies.map {|data| Reply.new(data)}
  end 

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_reply_id = options['parent_reply_id']
    @author_id = options['author_id']
    @body = options['body']
  end 

  def author 
    author = QuestionDatabase.instance.execute(<<-SQL, @author_id) 
      SELECT 
        *
      FROM 
        users
      WHERE 
        id = ?
      SQL
    
    User.new(author.first)
  end
    
  def question
    question = QuestionDatabase.instance.execute(<<-SQL, @question_id) 
      SELECT 
        *
      FROM 
        questions
      WHERE 
        id = ?
      SQL
    Question.new(question.first)
  end
  
  def parent_reply
    parent = QuestionDatabase.instance.execute(<<-SQL, @parent_reply_id) 
      SELECT 
        *
      FROM 
        replies
      WHERE 
        id = ?
      SQL
    return nil if parent.length == 0
    Reply.new(parent.first)
  end
  
  def child_replies 
    child = QuestionDatabase.instance.execute(<<-SQL, @id) 
      SELECT 
        *
      FROM 
        replies
      WHERE 
        parent_reply_id = ?
      SQL
    return nil if child.length == 0
    child.map {|data| Reply.new(data)}
  end
end



class QuestionFollow 
  
  def self.most_followed_questions(n)
    follow = QuestionDatabase.instance.execute(<<-SQL , n )
    SELECT 
    questions.id, questions.title, questions.body, questions.author_id
    FROM 
    questions JOIN question_follows ON questions.id = question_follows.question_id
    GROUP BY questions.id
    ORDER BY COUNT(*) DESC LIMIT ?
    SQL
    
    follow.map {|datum| Question.new(datum)}
  end
  
  def self.followers_for_question_id(ques_id)
    followers = QuestionDatabase.instance.execute(<<-SQL,ques_id)
    SELECT 
      users.id, users.fname, users.lname 
    FROM 
      users JOIN question_follows ON users.id = question_follows.user_id
    WHERE 
     question_follows.question_id = ?
    SQL
    followers.map {|data| User.new(data)}
  end
  
  def self.followed_questions_for_user_id(user_id)
    questions=QuestionDatabase.instance.execute(<<-SQL,user_id)
    SELECT 
      questions.id, questions.title, questions.body, questions.author_id
    FROM 
      questions JOIN question_follows ON questions.id = question_follows.question_id
    WHERE 
     question_follows.user_id = ?
    SQL
    questions.map {|data| Question.new(data)}
  end
  
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
    
  end
  
end

class QuestionLike 
  attr_accessor :id, :user_id, :question_id
  
  def self.most_liked_questions(n)
    most = QuestionDatabase.instance.execute(<<-SQL, n)
    SELECT 
      questions.id, questions.title, questions.body, questions.author_id
    FROM 
      questions JOIN question_likes ON questions.id = question_likes.question_id
    GROUP BY 
      questions.id 
    ORDER BY 
      COUNT(*) DESC LIMIT ?
    SQL
    most.map{|datum| Question.new(datum)}
  end
  

  
  def self.likers_for_questions(ques_id)
    likers = QuestionDatabase.instance.execute(<<-SQL, ques_id)
    SELECT
      users.id, users.fname, users.lname
    FROM 
      users JOIN question_likes ON users.id = question_likes.user_id 
    WHERE 
     question_likes.question_id = ?
     SQL
    likers.map{|datum| User.new(datum)}
  end
  
  def self.liked_questions_for_user_id(user_id)
    questions = QuestionDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      questions.id, questions.title, questions.body, questions.author_id
    FROM 
      questions JOIN question_likes ON questions.id = question_likes.question_id 
    WHERE 
      question_likes.user_id = ?
     SQL
    questions.map{|datum| Question.new(datum)}
  end
  
  def self.num_likes_for_question_id(question_id)
     num = QuestionDatabase.instance.execute(<<-SQL, question_id)
     SELECT 
      COUNT(*)
     FROM 
      question_likes
     WHERE 
      question_id = ?
     SQL
     num.first["COUNT(*)"]
  end 
  
  def initialize(options)
    @id = options['id']
    @user_id = options['user_id']
    @question_id = options['question_id']
  end
  

  

  
end