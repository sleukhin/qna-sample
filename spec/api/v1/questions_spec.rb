require 'rails_helper'

describe 'Questions API' do
  let(:user) { create(:user) }

  describe 'GET/index' do
    it_behaves_like 'api resource'

    context 'authorized' do
      let(:me) { create(:user) }
      let(:access_token) { create(:access_token, resource_owner_id: me.id) }
      let!(:questions) { create_list(:question_with_user, 2) }
      let(:question) { questions.first }

      before { get '/api/v1/questions', format: :json, access_token: access_token.token }

      it 'returns 200 status code' do
        expect(response).to be_success
      end

      it 'returns list of questions' do
        expect(response.body).to have_json_size(2).at_path('questions')
      end

      context 'question preview' do
        %w(id title created_at updated_at user_id).each do |attr|
          it "contains question object #{attr}" do
            expect(response.body).to(
              be_json_eql(question.send(attr.to_sym).to_json).at_path("questions/0/#{attr}")
            )
          end
        end
      end
    end

    def do_request(options = {})
      get '/api/v1/questions', { format: :json }.merge(options)
    end
  end

  describe 'GET/show' do
    let(:question) { create(:question, user: user) }
    let!(:answer) { create(:answer, user: user, question: question) }
    let!(:comment) { create(:comment, user: user, commentable: question) }
    let!(:attachment) { create(:attachment, attachmentable: question) }

    it_behaves_like 'api resource'

    context 'authorized' do
      let(:access_token) { create(:access_token, resource_owner_id: user.id) }

      before do
        get "/api/v1/questions/#{question.id}", format: :json, access_token: access_token.token
      end

      it 'returns 200 status code' do
        expect(response).to be_success
      end

      %w(id title body created_at updated_at).each do |attr|
        it "contains question object #{attr}" do
          expect(response.body).to(
            be_json_eql(question.send(attr.to_sym).to_json).at_path("question/#{attr}")
          )
        end
      end

      context 'answers' do
        it 'includes in question object' do
          expect(response.body).to have_json_size(1).at_path('question/answers')
        end

        %w(id body created_at updated_at user_id accepted).each do |attr|
          it "contains #{attr}" do
            expect(response.body).to(
              be_json_eql(answer.send(attr.to_sym).to_json).at_path("question/answers/0/#{attr}")
            )
          end
        end
      end

      it_behaves_like 'it has comments json' do
        let(:resource_name) { 'question' }
      end

      it_behaves_like 'it has attachments json' do
        let(:resource_name) { 'question' }
      end
    end

    def do_request(options = {})
      get "/api/v1/questions/#{question.id}", { format: :json }.merge(options)
    end
  end

  describe 'POST/create' do
    it_behaves_like 'api resource'

    context 'authorized' do
      let(:access_token) { create(:access_token, resource_owner_id: user.id) }

      let(:post_question) do
        post(
          '/api/v1/questions',
          format: :json,
          access_token: access_token.token,
          question: attributes_for(:question))
      end

      it 'returns status 201' do
        post_question
        expect(response.status).to eq 201
      end

      it 'saves the new question in the database' do
        expect { post_question }.to change(Question, :count).by(1)
      end
    end

    def do_request(options = {})
      post(
        '/api/v1/questions', { format: :json, question: attributes_for(:question) }.merge(options)
      )
    end
  end
end
