#coding: utf-8
require "find"
class Kindeditor::AssetsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create
    @imgFile, @dir = params[:imgFile], params[:dir]
    unless @imgFile.nil?
      if Kindeditor::AssetUploader.save_upload_info? # save upload info into database
        begin
          @asset = "Kindeditor::#{@dir.camelize}".constantize.new(:asset => @imgFile)
          @asset.owner_id = params[:owner_id] ? params[:owner_id] : 0
          @asset.owner_type = params[:owner_type] ? params[:owner_type] : ''
          logger.warn '========= Warning: the owner have not been created, "delete uploaded files automatically" will not work. =========' if defined?(logger) && @asset.owner_id == 0
          @asset.asset_type = @dir
          if @asset.save
            render :plain => ({:error => 0, :url => @asset.asset.url}.to_json)
          else
            show_error(@asset.errors.full_messages)
          end
        rescue Exception => e
          show_error(e.to_s)
        end
      else # do not touch database
        begin
          uploader = "Kindeditor::#{@dir.camelize}Uploader".constantize.new
          uploader.store!(@imgFile)
          render :plain => ({:error => 0, :url => uploader.url}.to_json)
        rescue CarrierWave::UploadError => e
          show_error(e.message)
        rescue Exception => e
          show_error(e.to_s)
        end
      end
    else
      show_error("No File Selected!")
    end
  end

  def list
    # @root_path = "#{Rails.public_path}/#{RailsKindeditor.upload_store_dir}/"
    # @root_url = "/#{RailsKindeditor.upload_store_dir}/"
     @img_ext = Kindeditor::AssetUploader::EXT_NAMES[:image]
    # @dir = params[:dir].strip || ""
    # unless Kindeditor::AssetUploader::EXT_NAMES.keys.map(&:to_s).push("").include?(@dir)
    #   render :plain => "Invalid Directory name."
    #   return
    # end
    #
    # Dir.chdir(Rails.public_path)
    # RailsKindeditor.upload_store_dir.split('/').each do |dir|
    #   Dir.mkdir(dir) unless Dir.exist?(dir)
    #   Dir.chdir(dir)
    # end
    #
    # Dir.mkdir(@dir) unless Dir.exist?(@dir)
    #
    # @root_path += @dir + "/"
    # @root_url += @dir + "/"
    #
    # @path = params[:path].strip || ""
    # if @path.empty?
    #   @current_path = @root_path
    #   @current_url = @root_url
    #   @current_dir_path = ""
    #   @moveup_dir_path = ""
    # else
    #   @current_path = @root_path + @path + "/"
    #   @current_url = @root_url + @path + "/"
    #   @current_dir_path = @path
    #   @moveup_dir_path = @current_dir_path.gsub(/(.*?)[^\/]+\/$/, "")
    # end
    # @order = %w(name size type).include?(params[:order].downcase) ? params[:order].downcase : "name"
    # if !@current_path.match(/\.\./).nil?
    #   render :plain => "Access is not allowed."
    #   return
    # end
    # if @current_path.match(/\/$/).nil?
    #   render :plain => "Parameter is not valid."
    #   return
    # end
    # if !File.exist?(@current_path) || !File.directory?(@current_path)
    #   render :plain => "Directory does not exist."
    #   return
    # end
    #
    #
    asset_base_host =  Rails.application.secrets["oss"]["aliyun_host"]+ '/uploads/image/'
    result_a = []

      # tem_r =[["201809/fade34b6-f4ed-4f70-b928-084e23b38a5d.jpg"], ["201809/9c51d0d2-aa99-4a25-9940-049eb14cb251.jpg"], ["201809/f764c3be-ccfc-4c4d-bafa-697e5412fa22.png"], ["201809/b93ce831-c47b-4f51-951f-b7f7955b48f0.jpg"], ["201809/f066f59b-58d2-480e-950a-bd452736ba12.jpg"], ["201810/305bb3c8-a110-4480-8981-75c744d8849d.jpg"], ["201810/abd5dedc-ce5a-4901-8ac8-a361b3312457.jpg"], ["201810/0f954d31-4c4d-4f4e-9b2f-820629a7800d.jpg"], ["201810/b7216d6b-bacb-42ce-a330-d890fa6a2cc1.png"], ["201810/d37aebd6-3e5f-48ea-81f3-cdbea28af35f.jpg"], ["201810/03371a4c-b40c-47dd-9675-58ef159f9c4b.jpg"], ["201810/33b93155-7168-43e1-9bae-d24d1e598f3e.jpg"], ["201810/5a25f14f-2a6d-48cc-bcb2-735f41fcad8c.jpg"], ["201811/700066ce-4f0a-4f2f-9dfb-2e4595cd1199.jpg"], ["201811/4a69ed56-885c-4f20-ab09-1b907337f6e9.jpg"], ["201811/4a201718-de18-4c02-b033-3aa6728aad49.jpg"], ["201811/711e75f0-78b8-43c1-9b3c-745041a9efae.jpg"], ["201811/9d66dafd-316a-4964-acc7-9d9cd36b6522.jpg"], ["201811/16a42872-9c7a-4858-8b3e-776e82f5acfb.jpg"], ["201811/e4373e83-aeef-439e-9311-b6370f5669a4.png"], ["201811/2437945c-7115-45f8-b65a-7cf808464ae9.png"], ["201811/93dedda8-ca7e-4063-ba40-5938389f5797.jpg"], ["201811/6a6e658b-92f4-4b7f-b081-a4d47e9ca0c7.png"], ["201811/07d3d9ee-4691-4a30-ac19-495e46946cf5.jpg"], ["201811/fb1cd74a-46a9-4ac3-864a-5842de5ebb19.png"]]
    Article.last(200).each do |ar|
      result_a += ar.content.scan /aliyuncs.com\/uploads\/image\/(.*?)\">/
    end
    @file_list = []
    result_a.each do |filename|
      hash = {}

          hash[:is_dir] = false
          hash[:has_file] = false
          hash[:filesize] = ''
          hash[:dir_path] = ""
          file_ext = filename.first.gsub(/.*\./,"")
        hash[:is_photo] = ["gif", "jpg", "jpeg", "png", "bmp"].include?(file_ext)
        hash[:filetype] = file_ext
        hash[:filename] = filename.first
        hash[:datetime] = ""
        @file_list << hash
      end


    #@file_list.sort! {|a, b| a["file#{@order}".to_sym] <=> b["file#{@order}".to_sym]}
    
    @result = {}
    @result[:moveup_dir_path] = nil
    @result[:current_dir_path] = asset_base_host
    @result[:current_url] = asset_base_host
    @result[:total_count] = @file_list.count
    @result[:file_list] = @file_list

    #
    # binding.pry
    render :plain => @result.to_json
  end
  
  private
  def show_error(msg)
    render :plain => ({:error => 1, :message => msg}.to_json)
  end
  
end