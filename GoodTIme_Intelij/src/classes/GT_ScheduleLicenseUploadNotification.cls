
global class GT_ScheduleLicenseUploadNotification implements schedulable
{
	global void execute(SchedulableContext sc)
	{
		GT_SendLicenseUploadReminder bc = new GT_SendLicenseUploadReminder();
		Database.executeBatch(bc);
	}
}