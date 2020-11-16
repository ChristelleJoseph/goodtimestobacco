
global class GT_ScheduleLicenseUploadNotification implements schedulable
{
	global void execute(SchedulableContext sc)
	{
		database.executebatch(new GT_SendLicenseUploadReminder());
	}
}