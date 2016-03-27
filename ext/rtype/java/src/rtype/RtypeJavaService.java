package rtype;

import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.runtime.load.BasicLibraryService;

public class RtypeJavaService implements BasicLibraryService {
	@Override
	public boolean basicLoad(Ruby ruby) throws IOException {
		Rtype.init(ruby);
		return true;
	}
}
