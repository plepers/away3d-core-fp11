package away3d.core.base {

	import flash.utils.Dictionary;
	import away3d.core.base.SubGeometry;

	/**
	 * @author Pierre Lepers
	 * away3d.core.base.CompositeSubGeom
	 */
	public class CompositeSubGeomSource extends VectorSubGeometry {

		public function CompositeSubGeomSource() {
			super();
			_groups = new Dictionary();
			_groupsIds = new Vector.<uint>();
		}

		public function setGroups( groups : Dictionary ) : void {
			_groups = groups;
			for ( var id : * in _groups ) {
				_groupsIds.push( id );
			}
		}

		public function setGroup( id : uint, indices : Vector.<uint> ) : void {
			_groups[ id ] = indices;
			_groupsIds.push( id );
		}


		public function createSub( groups : Vector.<uint> = null, invert : Boolean = false ) : CompositeSubGeom {
			var csg : CompositeSubGeom = new CompositeSubGeom( this );
			csg.setGroups( groups, invert );
			return csg; 
		}
		
		private var _groupsIds : Vector.<uint>;
		private var _groups : Dictionary;

		internal function get groupsIds() : Vector.<uint> {
			return _groupsIds;
		}

		internal function get groups() : Dictionary {
			return _groups;
		}
	}
}
