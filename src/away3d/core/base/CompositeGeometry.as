package away3d.core.base {

	import away3d.core.base.Geometry;

	/**
	 * @author Pierre Lepers
	 * away3d.core.base.CompositeGeometry
	 */
	public class CompositeGeometry extends Geometry {

		
		

		public function CompositeGeometry() {
			super();
			_compositeSources = new Vector.<CompositeSubGeomSource>();
			_compositeSubs = new Vector.<CompositeSubGeom>();
		}

		public function getNumSources() : int {
			return _compositeSources.length;
		}
//
//		public function removeComposites( groups : Vector.<uint> ) : void {
//			
//			
//		}
//
//		public function addComposites( groups : Vector.<uint> ) : void {
//			
//			
//			
//			for each (var source : CompositeSubGeomSource in _compositeSources ) {
//				source.createSub( groups );
//			}
		//
		// }
		
		override public function addSubGeometry(subGeometry : SubGeometry) : void
		{
			if( subGeometry is CompositeSubGeomSource ) {
				_compositeSources.push( subGeometry );
			}
			else {
				super.addSubGeometry(subGeometry);
				if( subGeometry is CompositeSubGeom )
					_compositeSubs.push( subGeometry );
			}
		}

		public function getSubComposite( at : uint ) : CompositeSubGeomSource {
			return _compositeSources[ at ];
		}


		public function clearSubs() : void {
			var sub : CompositeSubGeom;
			while( _compositeSubs.length > 0 ) {
				sub = _compositeSubs.pop() as CompositeSubGeom;
				removeSubGeometry( sub );
				sub.dispose();
			}
		}


		private var _compositeSources : Vector.<CompositeSubGeomSource>;
		private var _compositeSubs : Vector.<CompositeSubGeom>;
		
		
		
	}
}
