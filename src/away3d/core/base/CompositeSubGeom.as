package away3d.core.base {

	import away3d.bounds.BoundingBox;
	import flash.utils.Dictionary;
	import away3d.core.managers.Stage3DProxy;

	import flash.display3D.VertexBuffer3D;

	/**
	 * @author Pierre Lepers
	 * away3d.core.base.CompositeSubGeom
	 */
	public class CompositeSubGeom extends VectorSubGeometry {

		private var _source : CompositeSubGeomSource;
		private var _groups : Vector.<uint>;

		public function CompositeSubGeom(source : CompositeSubGeomSource ) {
			_source = source;
			autoDeriveVertexNormals = 
			autoDeriveVertexTangents = false;
			super();
		}
		
		
		override public function contributeBounds(bb : BoundingBox) : void {
			_source.contributeBounds(bb);
		}
		
		
		override public function dispose() : void {
			_source = null;
			super.dispose();
		}

		public function getGroups() : Vector.<uint> {
			return _groups;
		}

		public function removeGroups( remove : Vector.<uint> ) : void {
			for (var i : int = _groups.length-1; i > -1; i--) {
				if( remove.indexOf( _groups[i] ) > -1 ) _groups.splice(i, 1);
			}
			setGroups( _groups );
		}
		
		
		public function addGroups(add : Vector.<uint>) : void {
			for (var i : int = 0; i < add.length; i++) {
				if( _groups.indexOf( add[i] ) == -1 ) _groups.push( add[i] );
			}
			setGroups( _groups );
		}


		public function setGroups(groups : Vector.<uint> = null, invert : Boolean = false) : void {
			
			var groupsIds : Vector.<uint> = _source.groupsIds;
			var sg : Dictionary = _source.groups;
			
			if( groups == null ) 
				groups = _source.groupsIds;
				
			var args : Array = [];
			var i : int;
			var head : Vector.<uint>;
			
			if( invert ) {
				var ng : Vector.<uint> = new Vector.<uint>();
				for ( i = 0; i < groupsIds.length; i++) {
					if( groups.indexOf( groupsIds[i] ) == -1 ) 
						ng.push( groupsIds[i] );
				}
				groups = ng;
			} 
			
			for ( i = 1; i < groups.length; i++) 
				args.push( sg[ groups[i] ] );
			head = sg[ groups[0] ];
			
			_groups = groups;

			var indices : Vector.<uint> = head.concat.apply(head, args);
			updateIndexData( indices );
		}

		
		override public function get numVertices() : uint
		{
			return _source.numVertices;
		}

		
		override public function getVertexBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _source.getVertexBuffer(stage3DProxy);
		}

		override public function getUVBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _source.getUVBuffer(stage3DProxy);
		}
		
		override public function getSecondaryUVBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _source.getSecondaryUVBuffer(stage3DProxy);
		}
		
		override public function getVertexNormalBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _source.getVertexNormalBuffer(stage3DProxy);
		}

		override public function getVertexTangentBuffer(stage3DProxy : Stage3DProxy) : VertexBuffer3D
		{
			return _source.getVertexTangentBuffer(stage3DProxy);
		}
		
		override public function get vertexData() : Vector.<Number>
		{
			return _source.vertexData;
		}

	}
}
