class LkSlowlogController < ApplicationController
  def index
    
    #@instance_ids = SlowlogDetail.select("instance_id").distinct.pluck(:instance_id)
    @dbnames = SlowlogDetail.select("DBName").distinct.where("DBName<>'crm_prod_drds'").pluck(:DBName)

    @slowlog_detail =SlowlogDetail.select("id,instance_id,ReturnRowCounts,SQLText,ParseRowCounts,QueryTimes,DBName,ExecutionStartTime").where("1=1  and  SQLText like '%select%'")
    # "a > #{params[:b]} or "
    @slowlog_detail = @slowlog_detail.where(ExecutionStartTime: params[:sdatetime]..params[:edatetime]) if params[:sdatetime].present?

    # 根据实例ID查询    
    #@slowlog_detail = @slowlog_detail.where(instance_id: params[:instance_id]) if params[:instance_id].present?

    # 根据数据库名称查询
    @slowlog_detail = @slowlog_detail.where(dbname: params[:dbname]) if params[:dbname].present?
    
    @slowlog_detail = @slowlog_detail.page(params[:page]).per(10)

  end
end
