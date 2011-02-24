package QuickB2.misc 
{
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2_sliceFlags 
	{
		public static const IS_SLICEABLE:uint              = 0x00000001;
		public static const IS_PARTIALLY_SLICEABLE:uint    = 0x00000002;
		public static const ADDS_NEW_PARTS_TO_WORLD:uint   = 0x00000004;
		public static const REMOVES_SELF_FROM_WORLD:uint   = 0x00000008;
		public static const TRANSFERS_JOINTS_TO_PARTS:uint = 0x00000010;
		public static const CHANGES_OWN_GEOMETRY:uint      = 0x00000020;
	}
}