package away3d.core.base {

	import away3d.core.base.Geometry;

	/**
	 * @author Pierre Lepers
	 * away3d.core.base.CompositeGeometry
	 */
	public class BCompositeGeometry extends Geometry {

		
		

		public function BCompositeGeometry() {
			super();
			_compositeSources = new Vector.<BCompositeSubGeomSource>();
			_compositeSubs = new Vector.<BCompositeSubGeom>();
		}

		public function getNumSources() : int {
			return _compositeSources.length;
		}
		
		override public function addSubGeometry(subGeometry : SubGeometry) : void
		{
			if( subGeometry is BCompositeSubGeomSource ) {
				_compositeSources.push( subGeometry );
			}
			else {
				super.addSubGeometry(subGeometry);
				if( subGeometry is BCompositeSubGeom )
					_compositeSubs.push( subGeometry );
			}
		}
		
		
		override public function removeSubGeometry(subGeometry : SubGeometry) : void {
			super.removeSubGeometry(subGeometry);
			if( subGeometry is BCompositeSubGeom )
				_compositeSubs.splice(_compositeSubs.indexOf(subGeometry), 1);
			
		}

		public function getSubComposite( at : uint ) : BCompositeSubGeomSource {
			return _compositeSources[ at ];
		}


		public function clearSubs() : void {
			var sub : BCompositeSubGeom;
			while( _compositeSubs.length > 0 ) {
				sub = _compositeSubs.pop() as BCompositeSubGeom;
				removeSubGeometry( sub );
				sub.dispose();
			}
		}


		private var _compositeSources : Vector.<BCompositeSubGeomSource>;
		private var _compositeSubs : Vector.<BCompositeSubGeom>;
		
		
		
	}
}
