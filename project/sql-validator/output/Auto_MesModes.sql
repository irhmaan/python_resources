/* ===================template_1_section====================== */
	else if(@P_Mode='PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning')
	begin

		select * into #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_
		from PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_ t inner join
		PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_ t inner join
		PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_ t inner join
		PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_ t inner join
		PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning' as 'TableName'

	end
	else if(@P_Mode='PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing')
	begin

		select * into #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_
		from PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_ t inner join
		PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_ t inner join
		PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_ t inner join
		PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_ t inner join
		PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing' as 'TableName'

	end
	else if(@P_Mode='PUSH_OP30_ACTUATOR_CIRCLIP_ASSY')
	begin

		select * into #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_
		from PUSH_OP30_ACTUATOR_CIRCLIP_ASSY(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP30_ACTUATOR_CIRCLIP_ASSY' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_ t inner join
		PUSH_OP30_ACTUATOR_CIRCLIP_ASSY(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_ t inner join
		PUSH_OP30_ACTUATOR_CIRCLIP_ASSY(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_ t inner join
		PUSH_OP30_ACTUATOR_CIRCLIP_ASSY(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_ t inner join
		PUSH_OP30_ACTUATOR_CIRCLIP_ASSY(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP30_ACTUATOR_CIRCLIP_ASSY_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP30_ACTUATOR_CIRCLIP_ASSY' as 'TableName'

	end
	else if(@P_Mode='PUSH_OP40_PRE_ACTUATION_TESTING')
	begin

		select * into #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_
		from PUSH_OP40_PRE_ACTUATION_TESTING(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP40_PRE_ACTUATION_TESTING' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_ t inner join
		PUSH_OP40_PRE_ACTUATION_TESTING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_ t inner join
		PUSH_OP40_PRE_ACTUATION_TESTING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_ t inner join
		PUSH_OP40_PRE_ACTUATION_TESTING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_ t inner join
		PUSH_OP40_PRE_ACTUATION_TESTING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP40_PRE_ACTUATION_TESTING_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP40_PRE_ACTUATION_TESTING' as 'TableName'

	end
	else if(@P_Mode='PUSH_OP50_LEVER_PRESS_and_TORQUING')
	begin

		select * into #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_
		from PUSH_OP50_LEVER_PRESS_and_TORQUING(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP50_LEVER_PRESS_and_TORQUING' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_ t inner join
		PUSH_OP50_LEVER_PRESS_and_TORQUING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_ t inner join
		PUSH_OP50_LEVER_PRESS_and_TORQUING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_ t inner join
		PUSH_OP50_LEVER_PRESS_and_TORQUING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_ t inner join
		PUSH_OP50_LEVER_PRESS_and_TORQUING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP50_LEVER_PRESS_and_TORQUING_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP50_LEVER_PRESS_and_TORQUING' as 'TableName'

	end
	else if(@P_Mode='PUSH_OP60_HIGHT_CHECKING_INSPECTION')
	begin

		select * into #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_
		from PUSH_OP60_HIGHT_CHECKING_INSPECTION(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP60_HIGHT_CHECKING_INSPECTION' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_ t inner join
		PUSH_OP60_HIGHT_CHECKING_INSPECTION(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_ t inner join
		PUSH_OP60_HIGHT_CHECKING_INSPECTION(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_ t inner join
		PUSH_OP60_HIGHT_CHECKING_INSPECTION(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_ t inner join
		PUSH_OP60_HIGHT_CHECKING_INSPECTION(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP60_HIGHT_CHECKING_INSPECTION_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP60_HIGHT_CHECKING_INSPECTION' as 'TableName'

	end
	else if(@P_Mode='PUSH_OP70_SEAL_CHECKING')
	begin

		select * into #TEMP_PUSH_OP70_SEAL_CHECKING_
		from PUSH_OP70_SEAL_CHECKING(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP70_SEAL_CHECKING_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP70_SEAL_CHECKING_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP70_SEAL_CHECKING_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP70_SEAL_CHECKING_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP70_SEAL_CHECKING_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP70_SEAL_CHECKING_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP70_SEAL_CHECKING_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP70_SEAL_CHECKING' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP70_SEAL_CHECKING_ t inner join
		PUSH_OP70_SEAL_CHECKING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP70_SEAL_CHECKING_ t inner join
		PUSH_OP70_SEAL_CHECKING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP70_SEAL_CHECKING_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP70_SEAL_CHECKING_ t inner join
		PUSH_OP70_SEAL_CHECKING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP70_SEAL_CHECKING_ t inner join
		PUSH_OP70_SEAL_CHECKING(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP70_SEAL_CHECKING_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP70_SEAL_CHECKING' as 'TableName'

	end
	else if(@P_Mode='PUSH_OP80_PISTON_ASSY_PFT_and_LP')
	begin

		select * into #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_
		from PUSH_OP80_PISTON_ASSY_PFT_and_LP(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP80_PISTON_ASSY_PFT_and_LP' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_ t inner join
		PUSH_OP80_PISTON_ASSY_PFT_and_LP(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_ t inner join
		PUSH_OP80_PISTON_ASSY_PFT_and_LP(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_ t inner join
		PUSH_OP80_PISTON_ASSY_PFT_and_LP(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_ t inner join
		PUSH_OP80_PISTON_ASSY_PFT_and_LP(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP80_PISTON_ASSY_PFT_and_LP_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP80_PISTON_ASSY_PFT_and_LP' as 'TableName'

	end
	else if(@P_Mode='PUSH_OP90_HP_Adjuster_and_Torsion_angle_test')
	begin

		select * into #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_
		from PUSH_OP90_HP_Adjuster_and_Torsion_angle_test(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP90_HP_Adjuster_and_Torsion_angle_test' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_ t inner join
		PUSH_OP90_HP_Adjuster_and_Torsion_angle_test(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_ t inner join
		PUSH_OP90_HP_Adjuster_and_Torsion_angle_test(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_ t inner join
		PUSH_OP90_HP_Adjuster_and_Torsion_angle_test(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_ t inner join
		PUSH_OP90_HP_Adjuster_and_Torsion_angle_test(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP90_HP_Adjuster_and_Torsion_angle_test_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP90_HP_Adjuster_and_Torsion_angle_test' as 'TableName'

	end
	else if(@P_Mode='PUSH_OP100_Pad_Final_Assembly_and_Torquing')
	begin

		select * into #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_
		from PUSH_OP100_Pad_Final_Assembly_and_Torquing(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP100_Pad_Final_Assembly_and_Torquing' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_ t inner join
		PUSH_OP100_Pad_Final_Assembly_and_Torquing(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_ t inner join
		PUSH_OP100_Pad_Final_Assembly_and_Torquing(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_ t inner join
		PUSH_OP100_Pad_Final_Assembly_and_Torquing(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_ t inner join
		PUSH_OP100_Pad_Final_Assembly_and_Torquing(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP100_Pad_Final_Assembly_and_Torquing_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP100_Pad_Final_Assembly_and_Torquing' as 'TableName'

	end
	else if(@P_Mode='PUSH_OP110_ASR_and_Date_code')
	begin

		select * into #TEMP_PUSH_OP110_ASR_and_Date_code_
		from PUSH_OP110_ASR_and_Date_code(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP110_ASR_and_Date_code_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP110_ASR_and_Date_code_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP110_ASR_and_Date_code_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP110_ASR_and_Date_code_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP110_ASR_and_Date_code_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP110_ASR_and_Date_code_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP110_ASR_and_Date_code_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP110_ASR_and_Date_code' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP110_ASR_and_Date_code_ t inner join
		PUSH_OP110_ASR_and_Date_code(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP110_ASR_and_Date_code_ t inner join
		PUSH_OP110_ASR_and_Date_code(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP110_ASR_and_Date_code_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP110_ASR_and_Date_code_ t inner join
		PUSH_OP110_ASR_and_Date_code(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP110_ASR_and_Date_code_ t inner join
		PUSH_OP110_ASR_and_Date_code(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP110_ASR_and_Date_code_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP110_ASR_and_Date_code' as 'TableName'

	end
	else if(@P_Mode='PUSH_OP120_AUTO_INSPECTION')
	begin

		select * into #TEMP_PUSH_OP120_AUTO_INSPECTION_
		from PUSH_OP120_AUTO_INSPECTION(nolock) where ISNULL(TS_FLAG,0)=@INT_TS_FLAG
		and ISNULL(PROFITCENTER,'')=ISNULL(@P_PROFITCENTER_CODE,'') and ISNULL(CELLNO,'')=ISNULL(@P_LINE_CODE,'')
		and ISNULL(MachineCode,'')=@P_MACHINECODE and ISNULL(OperationCode,'')=ISNULL(@P_OPERATION_CODE,'')
		and DTS_SCAN is not null and DTS_PASS is not null

		update #TEMP_PUSH_OP120_AUTO_INSPECTION_ set STATUS= case when [STATUS]='PASS' then 'PS' else 'FL' end

		select @listCoulumnMain=COALESCE(@listCoulumnMain+ ',', '')
		+ 'isnull(convert(varchar(100),' + '[' + CONVERT(VARCHAR(100),main.TagName) + ']'  + '),''ND'')' + ' as ['
		+  CONVERT(VARCHAR(100),main.TagName) + ']'
		from MachineTagMapping(nolock)  main
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE

		while exists(select top 1 1 from #TEMP_PUSH_OP120_AUTO_INSPECTION_ )
		begin

		begin try

		select Top 1 @RFID=BARCODE,
		@STATUS=[STATUS]
		,@PassTimeStamp=DTS_PASS
		,@IsReworkPart=ISNULL(IsRework,0)
	    ,@MODELNO=MODEL_NO
		from #TEMP_PUSH_OP120_AUTO_INSPECTION_(nolock)
		order by DTS_PASS asc

						-- Rework
		if (@IsReworkPart=1)
		begin

				--EXEC ASSY_PROC_PULL_MES_DATA_REWORK @P_Mode = @P_Mode,
				--@P_PROFITCENTER_CODE = @P_PROFITCENTER_CODE,@P_LINE_CODE = @P_LINE_CODE,
				--@P_OPERATION_CODE = @P_OPERATION_CODE,@P_USER_ID = @P_USER_ID,
				--@P_MACHINECODE = @P_MACHINECODE,@P_BARCODE = @RFID,
				--@P_TABLENAME = @P_TABLENAME,
				--@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output


				--insert into assy_lineassystatus_running(
				--profitcentercode,linecode,machinecode,operationcode,stationcode,barcode,status,failcount,
				--datecode,partno,active,resulttimestamp,scantimestamp,userid,istallychartapproved,isreworkpart,ispendingpart,productionorderno,
				--PROD_LOT_NO,Live_Datecode
				--)
				--select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,
				--t.RFID,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,@IsReworkPart,r.IsPendingPart,
				--r.ProductionOrderNo,r.PROD_LOT_NO,@Live_Datecode from ASSY_LINEASSYSTATUS_RUNNING(nolock) r inner join #TEMP_PUSH_OP120_AUTO_INSPECTION_ t
				--on r.barcode = t.RFID
				--where r.MachineCode='MCIG'
				--and t.RFID=@RFID
				--and t.DTS_PASS=@PassTimeStamp

				SELECT TOP 1 @RFID = CASE WHEN isnull(Barcode,'')='' THEN @RFID ELSE Barcode END FROM ASSY_STATUS_REWORK_LOG WHERE Rework_Barcode=@RFID

				EXEC ASSY_PROC_REWORK @P_MODE='MOVE_REWORK_SAVED_DATA',
				@P_profitCenterCode = @P_PROFITCENTER_CODE,@P_lineCode = @P_LINE_CODE,
				@P_ReworkStation = @P_OPERATION_CODE,@P_UserCode = @P_USER_ID,
				@P_barcode = @RFID, @P_PartNo=@MODELNO,
				@TYPE_REWORK_PART_BARCODES = @TYPE_REWORK_PART_BARCODES,
				@ReturnValue = @ReturnValue output,@ReturnInt = @ReturnInt output
		end


		-- If Poke Yoke Barcode
		if (CHARINDEX('PKYK',@RFID) > 0)
		begin

				select @DCODE=Datecode,@MODELNO=Assy_PartNo,@WORKORDER=ProductionOrderNo
				from Assy_RunningPart(nolock) where ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 t.PROFITCENTRE,t.CELLNO,t.MachineCode,t.OperationCode,@StationCode,
				t.BARCODE,t.STATUS,t.FCA,'PKYK',@MODELNO,@Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,@IsTallyChartApproved,@IsReworkPart,@IsPendingPart,@WORKORDER,
				@PROD_LOT_NO from #TEMP_PUSH_OP120_AUTO_INSPECTION_ t
				where  t.BARCODE=@RFID
				and t.DTS_PASS=@PassTimeStamp

		end
		else
		begin
			if not exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock) where
			ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE and MachineCode=@P_MACHINECODE and
			OperationCode=@P_OPERATION_CODE and Barcode=@RFID
			)
			begin
			    begin try

				insert into Assy_LineAssyStatus_Running(
				ProfitCenterCode,LineCode,MachineCode,OperationCode,StationCode,Barcode,Status,FailCount,
				Datecode,PartNo,Active,ResultTimestamp,ScanTimestamp,UserID,IsTallyChartApproved,IsReworkPart,IsPendingPart,ProductionOrderNo,
				PROD_LOT_NO
				)
				select top 1 r.ProfitCenterCode,r.LineCode,t.MachineCode,t.OperationCode,r.StationCode,	t.BARCODE,t.STATUS,t.FCA,r.Datecode,r.PartNo,r.Active,t.DTS_PASS,t.DTS_SCAN,@P_USER_ID,r.IsTallyChartApproved,r.IsReworkPart,r.IsPendingPart,
				r.ProductionOrderNo,r.PROD_LOT_NO from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP120_AUTO_INSPECTION_ t
				on r.barcode = t.BARCODE
				where r.MachineCode='MCIG'
				and t.RFID=@RFID
				and t.DTS_PASS=@PassTimeStamp

				end try
				begin catch

					SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
					CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
					CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) + '|' +
					CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
					CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

					insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
					values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)

				end catch

			end
			else
			begin
				update r set r.Status=t.STATUS,
				       r.FailCount=t.FCA,
					   r.ResultTimestamp=t.DTS_PASS,
					   r.ScanTimestamp=t.DTS_SCAN
				from Assy_LineAssyStatus_Running(nolock) r inner join #TEMP_PUSH_OP120_AUTO_INSPECTION_ t
				on r.barcode = t.BARCODE
				where
				ProfitCenterCode=@P_PROFITCENTER_CODE and LineCode=@P_LINE_CODE
				and r.MachineCode=@P_MACHINECODE and r.OperationCode=@P_OPERATION_CODE
				and Barcode=@RFID
				and t.DTS_PASS=@PassTimeStamp

			end
		end
		set @Picked_Ids = @Picked_Ids+@@ROWCOUNT

		IF exists (select top 1 1 from Assy_LineAssyStatus_Running(nolock)
		where MachineCode=@P_MACHINECODE and OperationCode=@P_OPERATION_CODE
		and PROFITCENTERCODE = @P_PROFITCENTER_CODE
		AND LINECODE = @P_LINE_CODE AND Barcode=@RFID
		)
		begin


		IF(OBJECT_ID('HASH_TEMP_TAGDATA_10')) IS NOT NULL
		BEGIN
		DROP TABLE HASH_TEMP_TAGDATA_10
		END

		create table HASH_TEMP_TAGDATA_10
		(
			TagName varchar(100),
			TagValue varchar(100)
		)

		if( ISNULL(@listCoulumnMain,'')<>'')
		begin


				set @dynamic_query = '

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				select ' + @listCoulumnMain  +' into #TEMP_MES_DATA from ' + ' PUSH_OP120_AUTO_INSPECTION' +
				' where ' + 'BARCODE' + ' = '
				+'''' + @RFID + ''''
				+' and DTS_PASS = ' + '''' + convert(varchar,@PassTimeStamp,121) + ''''
				+ ' AND ISNULL(TS_FLAG,0)= '''+cast(@INT_TS_FLAG as varchar(2))+''' '
				+'
				DECLARE @Xmldata XML
				SET @Xmldata = (SELECT * FROM  #TEMP_MES_DATA FOR XML PATH(''''))

				SELECT TagName,TagValue FROM  (
				SELECT
				ROW_NUMBER()OVER(PARTITION BY   TagName ORDER BY  TagValue) rn,* FROM (
				SELECT  i.value(''local-name(.)'',''VARCHAR(100)'')  TagName,
				i.value(''.'',''VARCHAR(100)'') TagValue
				FROM @Xmldata.nodes(''//*'') x(i) ) tmp ) tmp1

				if object_id(''tempdb..#TEMP_MES_DATA'') is not null
				drop table #TEMP_MES_DATA

				'

				--print @dynamic_query
				insert into HASH_TEMP_TAGDATA_10(TagName,TagValue)
				execute(@dynamic_query)

		end

		delete from @ParameterData

		INSERT INTO @ParameterData(
		ProfitCenterCode,LineCode,MachineCode,
		OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
		select distinct @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
		@P_OPERATION_CODE,'1',@RFID,TagName,TagValue,@STATUS,'',@P_USER_ID
		from HASH_TEMP_TAGDATA_10

		if not exists(select top 1 1 from @ParameterData)
		begin
				insert into @ParameterData(
				ProfitCenterCode,LineCode,MachineCode,
				OperationCode,StationCode,Barcode,TagName,Value,Result,Datecode,UserID)
				select @P_PROFITCENTER_CODE,@P_LINE_CODE,@P_MACHINECODE,
				@P_OPERATION_CODE,'1',@RFID,'Result',@STATUS,@STATUS,'',@P_USER_ID
		end

		exec Assy_Proc_DBIntegration @Operation='INSERT_PLC_PARAMS',@LineCode=@P_LINE_CODE,
		@tblParameters=@ParameterData , @TD_Table=''

		delete from @ParameterData
		update p set TS_FLAG=2
		from #TEMP_PUSH_OP120_AUTO_INSPECTION_ t inner join
		PUSH_OP120_AUTO_INSPECTION(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG
		AND p.DTS_PASS=@PassTimeStamp

		delete p
		from #TEMP_PUSH_OP120_AUTO_INSPECTION_ t inner join
		PUSH_OP120_AUTO_INSPECTION(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=2
		AND p.DTS_PASS=@PassTimeStamp

		END

		delete from #TEMP_PUSH_OP120_AUTO_INSPECTION_ where rfid=@RFID and DTS_PASS=@PassTimeStamp
		END TRY
		BEGIN CATCH

		update p set TS_FLAG=100
		from #TEMP_PUSH_OP120_AUTO_INSPECTION_ t inner join
		PUSH_OP120_AUTO_INSPECTION(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=@INT_TS_FLAG

		delete p
		from #TEMP_PUSH_OP120_AUTO_INSPECTION_ t inner join
		PUSH_OP120_AUTO_INSPECTION(nolock) p on t.BARCODE=p.RFID
		and t.DTS_PASS=p.DTS_PASS
		where t.BARCODE=@RFID
		AND ISNULL(p.TS_FLAG,0)=100

		delete from #TEMP_PUSH_OP120_AUTO_INSPECTION_

		SET @ReturnValue =   CAST(ISNULL(ERROR_NUMBER(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_SEVERITY(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_STATE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_PROCEDURE(),'ASSY_PROC_PULL_MES_DATA') as varchar(200)) + '|' +
		CAST(ISNULL(ERROR_LINE(),0) as varchar(5)) + '|' +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500)) +
		CAST(ISNULL(ERROR_MESSAGE(),'') as varchar(1500))+ '|' +
		CAST(ISNULL(@P_Mode,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_PROFITCENTER_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_LINE_CODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_USER_ID,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_MACHINECODE,'') as varchar(100)) + '|' +
		CAST(ISNULL(@P_OPERATION_CODE,'') as varchar(100))

		SET @RETURNINT = 2

		insert into ASSY_LOG_ERROR(ErrorProcedure,ErrorMsg,Ent_dtl,MachineCode,OperationCode,Barcode,Mode)
		values('ASSY_PROC_PULL_MES_DATA',@ReturnValue,GETDATE(),@P_MACHINECODE,@P_OPERATION_CODE,@RFID,@P_Mode)


		END CATCH

	 END

	 select @Picked_Ids as 'PickedCount' , getdate() as 'PickedTime', 'PUSH_OP120_AUTO_INSPECTION' as 'TableName'

	end
/* ===================template_2_section====================== */
else if(@P_Mode='GET_PUSHED_DATA_COUNT')
begin
            select count(*) as 'PushedCount', 'PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning' as 'TableName'
            from PUSH_OP10_Continuity_testing_Air_and_vacuum_Cleaning(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
            select count(*) as 'PushedCount', 'PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing' as 'TableName'
            from PUSH_OP20_Sleeve_Cup_Seal_and_Pin_Pressing(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
            select count(*) as 'PushedCount', 'PUSH_OP30_ACTUATOR_CIRCLIP_ASSY' as 'TableName'
            from PUSH_OP30_ACTUATOR_CIRCLIP_ASSY(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
            select count(*) as 'PushedCount', 'PUSH_OP40_PRE_ACTUATION_TESTING' as 'TableName'
            from PUSH_OP40_PRE_ACTUATION_TESTING(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
            select count(*) as 'PushedCount', 'PUSH_OP50_LEVER_PRESS_and_TORQUING' as 'TableName'
            from PUSH_OP50_LEVER_PRESS_and_TORQUING(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
            select count(*) as 'PushedCount', 'PUSH_OP60_HIGHT_CHECKING_INSPECTION' as 'TableName'
            from PUSH_OP60_HIGHT_CHECKING_INSPECTION(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
            select count(*) as 'PushedCount', 'PUSH_OP70_SEAL_CHECKING' as 'TableName'
            from PUSH_OP70_SEAL_CHECKING(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
            select count(*) as 'PushedCount', 'PUSH_OP80_PISTON_ASSY_PFT_and_LP' as 'TableName'
            from PUSH_OP80_PISTON_ASSY_PFT_and_LP(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
            select count(*) as 'PushedCount', 'PUSH_OP90_HP_Adjuster_and_Torsion_angle_test' as 'TableName'
            from PUSH_OP90_HP_Adjuster_and_Torsion_angle_test(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
            select count(*) as 'PushedCount', 'PUSH_OP100_Pad_Final_Assembly_and_Torquing' as 'TableName'
            from PUSH_OP100_Pad_Final_Assembly_and_Torquing(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
            select count(*) as 'PushedCount', 'PUSH_OP110_ASR_and_Date_code' as 'TableName'
            from PUSH_OP110_ASR_and_Date_code(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
            select count(*) as 'PushedCount', 'PUSH_OP120_AUTO_INSPECTION' as 'TableName'
            from PUSH_OP120_AUTO_INSPECTION(nolock) where ISNULL(TS_FLAG,0)=0
            UNION
end
