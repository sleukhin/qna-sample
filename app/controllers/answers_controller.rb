class AnswersController < ApplicationController
  before_action :get_question
  before_action :load_answer, only: [:show, :edit, :update, :destroy]

  def index
    @answers = @question.answers
  end

  def show
  end

  def new
    @answer = Answer.new
  end

  def edit
  end

  def create
    @answer = @question.answers.new(answer_params)
    if @answer.save
      redirect_to [@question, @answer]
    else
      render :new
    end
  end

  def update
    if @answer.update(answer_params)
      redirect_to [@question, @answer]
    else
      render :edit
    end
  end

  def destroy
    @answer = @question.answers.find(params[:id])
    @answer.destroy
    redirect_to question_answers_path
  end

  private

  def get_question 
    @question = Question.find(params[:question_id])
  end

  def load_answer
    @answer = @question.answers.find(params[:id])
  end  

  def answer_params
    params.require(:answer).permit(:body)
  end
end
