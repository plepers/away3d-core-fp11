package away3d.core.base {

	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

	/**
	 * @author Pierre Lepers
	 * away3d.core.base.CompositeSubGeom
	 */
	public class BCompositeSubGeomSource extends BinarySubGeometry {


		public function BCompositeSubGeomSource(indexData : ByteArray) {
			super();
			_gindexData = indexData;
			_groups = new Dictionary();
			_groupsIds = new Vector.<uint>();
		}

		public function setGroups( groups : Dictionary/*IndicesRange*/ ) : void {
			_groups = groups;
			for ( var id : * in _groups ) {
				_groupsIds.push( id );
			}
		}

		public function setGroup( id : uint, indices : IndicesRange ) : void {
			_groups[ id ] = indices;
			_groupsIds.push( id );
		}

		public function hasGroups( groups : Vector.<uint> ) : Boolean {
			for (var i : int = 0; i < groups.length; i++) {
				if( _groupsIds.indexOf(groups[i]) == -1 ) return false;
			}
			
			return true;
		}



		public function createSub( groups : Vector.<uint> = null, invert : Boolean = false ) : BCompositeSubGeom {
			var csg : BCompositeSubGeom = new BCompositeSubGeom( this );
			csg.setGroups( groups, invert );
			return csg; 
		}
		
		private var _groupsIds : Vector.<uint>;
		private var _groups : Dictionary;
		private var _gindexData : ByteArray;

		internal function get groupsIds() : Vector.<uint> {
			return _groupsIds;
		}

		internal function get groups() : Dictionary {
			return _groups;
		}

		internal function get gindexData() : ByteArray {
			return _gindexData;
		}
	}
}
