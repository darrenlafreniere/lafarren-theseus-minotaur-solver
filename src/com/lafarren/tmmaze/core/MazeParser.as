//
// Copyright 2010, Darren Lafreniere
// <http://www.lafarren.com/theseus-minotaur-solver/>
// 
// This file is part of lafarren.com's Theseus and Minotaur Maze Solver,
// or tmmaze-solver.
// 
// tmmaze-solver is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// tmmaze-solver is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with tmmaze-solver, named License.txt. If not, see
// <http://www.gnu.org/licenses/>.
//
package com.lafarren.tmmaze.core
{
	import mx.controls.Alert;
	
	/**
	 * <p>
	 * 	Parses a collection of mazes from an XML file, and generates a
	 * 	MazeDefinition object for each valid maze read. Vertical and horizontal
	 * 	wall data is stored in two separate 2-dimensional arrays. A horizontal
	 * 	wall is marked by a <code>-</code>, and a vertical wall is marked by a
	 * 	<code>|</code>. Open gaps between tiles must be marked by an 'o'.
	* </p>
	* <p>
	* 	Format example:
	* 	<pre>
	* 	&lt;?xml version="1.0" encoding='UTF-8'?&gt;
	* 	&lt;mazes&gt;
	* 	    &lt;maze&gt;
	* 	        &lt;name&gt;Maze 1 (3 x 3)&lt;/name&gt;
	* 	        &lt;data&gt;
	* 	            &lt;walls&gt;
	* 	                &lt;horizontal&gt;
	* 	                    &lt;row&gt;---o&lt;/row&gt;
	* 	                    &lt;row&gt;o-o-&lt;/row&gt;
	* 	                    &lt;row&gt;o-o-&lt;/row&gt;
	* 	                    &lt;row&gt;---o&lt;/row&gt;
	* 	                &lt;/horizontal&gt;
	* 	                &lt;vertical&gt;
	* 	                    &lt;row&gt;|oo|o&lt;/row&gt;
	* 	                    &lt;row&gt;|o|o|&lt;/row&gt;
	* 	                    &lt;row&gt;|oo|o&lt;/row&gt;
	* 	                &lt;/vertical&gt;
	* 	            &lt;/walls&gt;
	* 	            &lt;positions&gt;
	* 	                &lt;position id="theseus"&gt;
	* 	                    &lt;x&gt;1&lt;/x&gt;
	* 	                    &lt;y&gt;2&lt;/y&gt;
	* 	                &lt;/position&gt;
	* 	                &lt;position id="minotaur"&gt;
	* 	                    &lt;x&gt;1&lt;/x&gt;
	* 	                    &lt;y&gt;0&lt;/y&gt;
	* 	                &lt;/position&gt;
	* 	                &lt;position id="exit"&gt;
	* 	                    &lt;x&gt;3&lt;/x&gt;
	* 	                    &lt;y&gt;1&lt;/y&gt;
	* 	                &lt;/position&gt;
	* 	            &lt;/positions&gt;
	* 	        &lt;/data&gt;
	* 	    &lt;/maze&gt;
	* 	    &lt;maze&gt;
	* 	        ...
	* 	    &lt;/maze&gt;
	* 	    &lt;maze&gt;
	* 	        ...
	* 	    &lt;/maze&gt;
	* 	    ...
	* 	&lt;/mazes&gt;
	* 	</pre>
	* </p>
	* 
	* @see MazeDefinition MazeDefinition for information on the horizontal and vertical wall data split.
	 */
	public class MazeParser
	{
		/**
		 * Uses E4X to parse the XML file for maze data.
		 * @param	xml The XML document that contains maze data.
		 * @return	A Vector of MazeDefinition objects that were successfully generated from the XML.
		 */
		// TODO: Modify interface to provide error feedback per <maze> entry.
		public static function parse(mazesXml:XML):Vector.<MazeDefinition>
		{
			var result:Vector.<MazeDefinition> = new Vector.<MazeDefinition>();
			
			// Iterate over every <maze> in the <mazes> collection.
			for each (var mazeXml:XML in mazesXml.maze)
			{
				var mazeDefinition:MazeDefinition = null;
				try
				{
					mazeDefinition = parseMaze(mazeXml);
				}
				catch (error:Error)
				{
					Alert.show("MazeParser.parse error: " + error.name + "\n\n" + error.message);
				}
				
				if (mazeDefinition)
				{
					result.push(mazeDefinition);
				}
			}
			
			return result;
		}
		
		private static function parseMaze(mazeXml:XML):MazeDefinition
		{
			var result:MazeDefinition = new MazeDefinition();
			result.name = mazeXml.name;
			
			try
			{
				var rowData:String;
				
				// Determine and set the size of the maze
				{
					// Determine the height by using the max height between the two wall data.
					// Horizontal wall data actually has height + 1 rows, so drop one.
					var height:int = Math.max
					(
						mazeXml.data.walls.horizontal.row.length() - 1,
						mazeXml.data.walls.vertical.row.length()
					);
					
					// The width must be determined by iterating over the rows and using the max
					// width of all rows.
					// Vertical wall data actually has width + 1 columns, so drop one.
					var width:int = 0; 
					for each (rowData in mazeXml.data.walls.horizontal.row)
					{
						width = Math.max(width, rowData.length);
					}
					for each (rowData in mazeXml.data.walls.vertical.row)
					{
						width = Math.max(width, rowData.length - 1);
					}
					
					if (width == 0 || height == 0)
					{
						throw new Error("Maze has zero size (name: \"" + result.name + "\")");
					}
					
					result.resize(width, height);
				}
				
				// Parse the wall data into the MazeDefinition. Assumes that wall data is
				// initialized to false by default.
				{
					var row:int;
					var col:int;
					
					row = 0;
					for each (rowData in mazeXml.data.walls.horizontal.row)
					{
						for (col = 0; col < rowData.length; ++col)
						{
							if (rowData.charAt(col) == '-')
							{
								result.setHorizontalWall(col, row, true);
							}
						}
						
						++row;
					}
					
					row = 0;
					for each (rowData in mazeXml.data.walls.vertical.row)
					{
						for (col = 0; col < rowData.length; ++col)
						{
							if (rowData.charAt(col) == '|')
							{
								result.setVerticalWall(col, row, true);
							}
						}
						
						++row;
					}
				}
				
				// Parse and set positions
				{
					var theseus:XML = mazeXml.data.positions.position.(attribute('id') == 'theseus')[0];
					result.setEntityPosition(EntityType.THESEUS, new PointInt(theseus.x, theseus.y));
					
					var minotaur:XML = mazeXml.data.positions.position.(attribute('id') == 'minotaur')[0];
					result.setEntityPosition(EntityType.MINOTAUR, new PointInt(minotaur.x, minotaur.y));
					
					var exit:XML = mazeXml.data.positions.position.(attribute('id') == 'exit')[0];
					result.setEntityPosition(EntityType.EXIT, new PointInt(exit.x, exit.y));
				}
			}
			catch (error:Error)
			{
				if (result.name.length > 0)
				{
					error.message = "Maze name: " + result.name + "\n" + error.message;
				}
				
				throw error;
			}
			
			return result;
		}
	}
}
