class ContactsController < ApplicationController
  def new; end

  def create
    redirect_to new_contact_path, notice: "お問い合わせありがとうございます（準備中）"
  end
end
