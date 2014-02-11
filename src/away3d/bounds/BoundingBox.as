package away3d.bounds {
	/**
	 * @author Pierre Lepers
	 * away3d.bounds.BoundingBox
	 */
	public class BoundingBox {
		
		public function BoundingBox() {
			minX = 
			minY = 
			minZ = Number.POSITIVE_INFINITY;
			
			maxX = 
			maxY = 
			maxZ = Number.NEGATIVE_INFINITY;
		}
		
		public var minX:Number;
		public var minY:Number;
		public var minZ:Number;
		public var maxX:Number;
		public var maxY:Number;
		public var maxZ:Number;

	}
	

}
